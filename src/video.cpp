#include "video.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Video::_bind_methods() {
	ClassDB::bind_method(D_METHOD("open_video", "_path"), &Video::open_video);
	ClassDB::bind_method(D_METHOD("close_video"), &Video::close_video);
	ClassDB::bind_method(D_METHOD("get_audio"), &Video::get_audio);
	ClassDB::bind_method(D_METHOD("seek_frame", "a_frame_nr"), &Video::seek_frame);
	ClassDB::bind_method(D_METHOD("next_frame"), &Video::next_frame);
	ClassDB::bind_method(D_METHOD("get_total_frame_nr"), &Video::get_total_frame_nr);
	ClassDB::bind_method(D_METHOD("get_avg_framerate"), &Video::get_avg_framerate);
	ClassDB::bind_method(D_METHOD("get_r_framerate"), &Video::get_r_framerate);

		
}

Video::Video() {
	// Initialize any variables here.
	is_open = false;
	av_format_ctx = nullptr;
	av_stream_audio = nullptr;
	av_stream_video = nullptr;
	av_codec_ctx_audio = nullptr;
	av_codec_ctx_video = nullptr;

	av_frame = nullptr;
	av_packet = nullptr;

	swr_ctx = nullptr;
	sws_ctx = nullptr;

	response = 0;

	start_time_audio = 0;
	start_time_video = 0;
	frame_timestamp = 0;
	current_pts = 0;
	average_frame_duration = 0;
	stream_time_base_video = 0;
	stream_time_base_audio = 0;
	total_frame_nr = 0;
	
}

Video::~Video() {
	// Add your cleanup here.
	close_video();
}

void Video::open_video(String _path){

	UtilityFunctions::print("Opening video");
	
	// Allocate video file context
	av_format_ctx = avformat_alloc_context();
	

	
	if (!av_format_ctx){
		UtilityFunctions::printerr("Couldn't allocate av format context!");
		return;
	}
	
	//Open file with avformat
	if (avformat_open_input(&av_format_ctx, _path.utf8(), NULL, NULL)){
		UtilityFunctions::printerr("Couldn't open video file!");
		close_video();
		return;
	}

	//find stream information
	if (avformat_find_stream_info(av_format_ctx, NULL)) {
		UtilityFunctions::printerr("Couldn't find stream info!");
		close_video();
		return;
	}

	//getting the audio & video
	for (int i= 0; i<av_format_ctx->nb_streams; i++){
		AVCodecParameters* av_codec_params = av_format_ctx->streams[i]->codecpar;

		if (!avcodec_find_decoder(av_codec_params->codec_id)){
			continue;
		} else if (av_codec_params->codec_type == AVMEDIA_TYPE_AUDIO){
			av_stream_audio = av_format_ctx->streams[i];
		} else if (av_codec_params->codec_type == AVMEDIA_TYPE_VIDEO){
			av_stream_video = av_format_ctx->streams[i];
		}
	}

	//Video Decoder Setup
	
	//Setup Decoder codec context
	const AVCodec* av_codec_video = avcodec_find_decoder(av_stream_video->codecpar->codec_id);
	if (av_codec_video==nullptr){ //this probably always returns true?
		UtilityFunctions::print("Couldn't find any codec decoder for video!!");
		close_video();
		return;
	}

	//Allocade codec context for decoder
	av_codec_ctx_video = avcodec_alloc_context3(av_codec_video);
	if (av_codec_ctx_video == nullptr) {
		UtilityFunctions::printerr("Couldn't allocate codec context for video.");
		close_video();
		return;
	} 

	//Copying video paramaters
	if (avcodec_parameters_to_context(av_codec_ctx_video, av_stream_video->codecpar)){
		UtilityFunctions::printerr("Couldn't initialize codec context for video.");
		close_video();
		return;
	}

	//Enable multithreading for decoding video
	//set codec to determine how many threads suits best
	av_codec_ctx_video->thread_count = 0;
	if (av_codec_video->capabilities & AV_CODEC_CAP_FRAME_THREADS){
		UtilityFunctions::print("video threading: frame");
		av_codec_ctx_video->thread_type = FF_THREAD_FRAME;
	} else if (av_codec_video->capabilities & AV_CODEC_CAP_SLICE_THREADS){
		av_codec_ctx_video->thread_type = FF_THREAD_SLICE;
		UtilityFunctions::print("video threading: slice");
	} else {
		av_codec_ctx_video->thread_count = 1; //multi-threaded decoding not possible
	}

	//Open Codecs
	if (avcodec_open2(av_codec_ctx_video, av_codec_video, NULL)){
		UtilityFunctions::printerr("Couldn't open video codec!");
		close_video();
		return;
	}

	sws_ctx= sws_getContext(
		av_codec_ctx_video->width, av_codec_ctx_video->height, (AVPixelFormat)av_stream_video->codecpar->format,
		av_codec_ctx_video->width, av_codec_ctx_video->height, AV_PIX_FMT_RGB24,
		SWS_BILINEAR, NULL, NULL, NULL);

	
	if(sws_ctx==nullptr){
		UtilityFunctions::printerr("couldn't get SWS context");
		close_video();
		return;
	}

	//Byte array setup
	byte_array.resize(av_codec_ctx_video->width * av_codec_ctx_video->height * 3); //*3 for each RGB channel, *4 if A
	src_linesize[0] = av_codec_ctx_video->width*3;

	//set other variables
	stream_time_base_video = av_q2d(av_stream_video->time_base) * 1000.0 * 10000.0; //converting from timebase to ticks
	start_time_video = av_stream_video->start_time != AV_NOPTS_VALUE ? (long)(av_stream_video->start_time * stream_time_base_video): 0;
	average_frame_duration = 10000000.0 / av_q2d(av_stream_video->avg_frame_rate); // 1s / 25fps = 400 ticks (40ms)
	
	_get_total_frame_nr();

	//Audio Decoder Setup
	const AVCodec* av_codec_audio = avcodec_find_decoder(av_stream_audio->codecpar->codec_id);
	if (av_codec_audio == nullptr){ 
		UtilityFunctions::printerr("Couldn't find any codec decoder for audio!!");
		close_video();
		return;
	}

	//Allocade codec context for decoder
	av_codec_ctx_audio = avcodec_alloc_context3(av_codec_audio);
	if (av_codec_ctx_audio == nullptr) {
		UtilityFunctions::printerr("Couldn't allocate codec context for audio.");
		close_video();
		return;
	} 


	
	//Copying audio paramaters
	if (avcodec_parameters_to_context(av_codec_ctx_audio, av_stream_audio->codecpar)){
		UtilityFunctions::printerr("Couldn't initialize codec context for audio.");
		close_video();
		return;
	} 
	
	
	//Enable multithreading for decoding Audio
	//set codec to determine how many threads suits best
	av_codec_ctx_audio->thread_count = 0;
	if (av_codec_audio->capabilities & AV_CODEC_CAP_FRAME_THREADS){
		av_codec_ctx_audio->thread_type = FF_THREAD_FRAME;
	} else if (av_codec_audio->capabilities & AV_CODEC_CAP_SLICE_THREADS){
		av_codec_ctx_audio->thread_type = FF_THREAD_SLICE;
	} else {
		av_codec_ctx_audio->thread_count = 1; //multi-threaded decoding not possible
	}


	
	//Open Codecs
	if (avcodec_open2(av_codec_ctx_audio, av_codec_audio, NULL)){
		UtilityFunctions::printerr("Couldn't open audio codec!");
		close_video();
		return;
	}

	av_codec_ctx_audio->request_sample_fmt = AV_SAMPLE_FMT_S16;

	//setup SWR for converting frame
	response = swr_alloc_set_opts2(
		&swr_ctx,
		&av_codec_ctx_audio->ch_layout, AV_SAMPLE_FMT_S16, av_codec_ctx_audio->sample_rate,
		&av_codec_ctx_audio->ch_layout, av_codec_ctx_audio->sample_fmt, av_codec_ctx_audio->sample_rate,
		0, nullptr);


	if (response < 0){
		print_av_error("Failed to obtain SWR context!");
		close_video();
		return;
	} 
	
	if (swr_ctx == nullptr ){
		print_av_error("Could Not Allocate re-sampler context");
		close_video();
		return;

	}

	response = swr_init(swr_ctx);
	if (response <0 ){
		print_av_error("Could Not Initialize re-sampler context");
		close_video();
		return;
	}

	//setting up start time
	stream_time_base_audio = av_q2d(av_stream_audio->time_base) * 1000.0 * 10000.0; //converting from timebase to ticks
	start_time_audio = av_stream_audio->start_time != AV_NOPTS_VALUE ? (long)(av_stream_audio->start_time * stream_time_base_audio): 0;

	
	is_open = true;
	UtilityFunctions::print("Video Opened @ ", _path);


	
}


void Video::close_video(){
	
	is_open = false;

	

	if (av_format_ctx != nullptr){
		avformat_close_input(&av_format_ctx);
	}

	if (av_codec_ctx_audio != nullptr ) {
		avcodec_free_context(&av_codec_ctx_audio);
	}

	if (av_codec_ctx_video != nullptr ) {
		avcodec_free_context(&av_codec_ctx_video);
	}
	if (swr_ctx != nullptr){
		swr_free(&swr_ctx);
	}

	if (sws_ctx != nullptr){
		sws_freeContext(sws_ctx);
	}
	if (av_frame != nullptr ) {
		av_frame_free(&av_frame);
	}
	if (av_packet != nullptr ) {
		av_packet_free(&av_packet);
	}
	
	UtilityFunctions::print("Video closed!");
}

void Video::print_av_error(const char* a_message){
	char l_error_buffer[AV_ERROR_MAX_STRING_SIZE];
	av_strerror(response, l_error_buffer, sizeof(l_error_buffer));
	UtilityFunctions::printerr((std::string(a_message)+ l_error_buffer).c_str());

}

Ref<AudioStreamWAV> Video::get_audio(){
	Ref<AudioStreamWAV> l_audio_wav = memnew(AudioStreamWAV);

	if (!is_open){
		UtilityFunctions::printerr("Video not open yet!");
		return l_audio_wav;
	}

	//set the seeker to the begining
	response = av_seek_frame(av_format_ctx, av_stream_audio->index, start_time_audio, AVSEEK_FLAG_FRAME | AVSEEK_FLAG_ANY);
	avcodec_flush_buffers(av_codec_ctx_audio);
	if (response < 0){
		UtilityFunctions::printerr("VCan't seek audio to beginning!");
		return l_audio_wav;
	}

	av_packet = av_packet_alloc();
	av_frame = av_frame_alloc();
	PackedByteArray l_audio_data = PackedByteArray();
	size_t l_audio_size = 0;

	while (av_read_frame(av_format_ctx, av_packet) >= 0){
		if (av_packet->stream_index == av_stream_audio->index){
			response = avcodec_send_packet(av_codec_ctx_audio, av_packet);
			if (response < 0){
				UtilityFunctions::printerr("Can't decode audio packet!");
				av_packet_unref(av_packet);
				break;
			}
			while (response >= 0){
				response = avcodec_receive_frame(av_codec_ctx_audio, av_frame);
				if (response == AVERROR(EAGAIN) || response == AVERROR_EOF){
					break;
				} else if (response<0){
					UtilityFunctions::printerr("Can't decode audio frame!");
					break;
				}

				// Copy decoded data to new frame
				AVFrame* l_av_new_frame = av_frame_alloc();
				l_av_new_frame->format = AV_SAMPLE_FMT_S16;
				l_av_new_frame->ch_layout = av_frame->ch_layout;
				l_av_new_frame->sample_rate = av_frame->sample_rate;
				l_av_new_frame->nb_samples = swr_get_out_samples(swr_ctx, av_frame->nb_samples);

				response = av_frame_get_buffer(l_av_new_frame, 0);
				if (response < 0){
					print_av_error("Couldn't create new frame for swr!");
					av_frame_unref(av_frame);
					av_frame_unref(l_av_new_frame);
					break;
				}

				response = swr_convert_frame(swr_ctx, l_av_new_frame, av_frame);
				if (response < 0){
					print_av_error("could not convert frame");
					av_frame_unref(av_frame);
					av_frame_unref(l_av_new_frame);
					break;
				}


				size_t l_byte_size = l_av_new_frame->nb_samples * av_get_bytes_per_sample(AV_SAMPLE_FMT_S16);

				//check if stereo
				if (av_codec_ctx_audio->ch_layout.nb_channels >= 2){
					l_byte_size *= 2;

				}

				l_audio_data.resize(l_audio_size + l_byte_size);
				memcpy(&(l_audio_data.ptrw()[l_audio_size]), l_av_new_frame->extended_data[0], l_byte_size);
				l_audio_size += l_byte_size;


				av_frame_unref(av_frame);
			}
		}


		av_packet_unref(av_packet);
	}

	//cleanup
	av_frame_free(&av_frame);
	av_packet_free(&av_packet);

	//Audio Creation
	l_audio_wav->set_format(l_audio_wav->FORMAT_16_BITS);
	l_audio_wav->set_data(l_audio_data);
	l_audio_wav->set_mix_rate(av_codec_ctx_audio->sample_rate);
	l_audio_wav->set_stereo(av_codec_ctx_audio->ch_layout.nb_channels >= 2);
	//UtilityFunctions::print("sample rate: ", av_codec_ctx_audio->sample_rate);

	return l_audio_wav;
	
}

Ref<Image> Video::seek_frame(int a_frame_nr){
	Ref<Image> l_image = memnew(Image);

	if (!is_open){
		UtilityFunctions::printerr("Video not yet open!");
		return l_image;
	}

	av_packet = av_packet_alloc();
	av_frame = av_frame_alloc();

	frame_timestamp = (long)(a_frame_nr * average_frame_duration);

	//Video Seeking
	response = av_seek_frame(av_format_ctx, -1, (start_time_video+frame_timestamp)/10, AVSEEK_FLAG_FRAME | AVSEEK_FLAG_BACKWARD);
	avcodec_flush_buffers(av_codec_ctx_video);
	if (response < 0){
		UtilityFunctions::printerr("VCan't seek video to beginning!");
		av_frame_free(&av_frame);
		av_packet_free(&av_packet);
		return l_image;
	}

	
	
	while(true){
		//Demux the video
		response = av_read_frame(av_format_ctx, av_packet);
		if (response != 0){
			av_packet_unref(av_packet);
			//UtilityFunctions::printerr("Could not read frame");
			break;
		}

		if (av_packet->stream_index != av_stream_video->index){
			av_packet_unref(av_packet);
			continue;
		}

		//send packet for decoding
		response = avcodec_send_packet(av_codec_ctx_video, av_packet);
		if (response!=0){ 
			av_packet_unref(av_packet);
			break;}

		//valid packet found, decode frame
		while(true){
			//receive all frames
			response = avcodec_receive_frame(av_codec_ctx_video, av_frame);
			if (response != 0){
				av_frame_unref(av_frame);
				break;
			}

			current_pts = av_frame-> best_effort_timestamp == AV_NOPTS_VALUE ? av_frame->pts : av_frame->best_effort_timestamp;
			if (current_pts == AV_NOPTS_VALUE){
				av_frame_unref(av_frame);
				continue;
			}

			//skip to requested frame
			if ((long)(current_pts * stream_time_base_video) / 10000 < frame_timestamp / 10000){
				av_frame_unref(av_frame);
				continue;
			}


			uint8_t* l_dest_data[1] = {byte_array.ptrw()};
			sws_scale(sws_ctx, av_frame->data, av_frame->linesize, 0, av_frame->height, l_dest_data, src_linesize);
			//the tutorial sets this to av_frame-> width/height, but that shows 0.
			l_image->set_data(av_frame->width, av_frame->height, 0, l_image->FORMAT_RGB8, byte_array);
			//UtilityFunctions::printerr("av_frame: ", av_frame->width, av_frame->height);
			//UtilityFunctions::printerr("image:", l_image->get_width(), l_image->get_height());
			//UtilityFunctions::printerr("av_codec_ctx context: ", av_codec_ctx_video->width, av_codec_ctx_video->height);
			av_frame_unref(av_frame);
			av_frame_free(&av_frame);
			av_packet_free(&av_packet);

			return l_image;

		}
		
		

		
	}
	
	//cleanup
	av_frame_free(&av_frame);
	av_packet_free(&av_packet);


	return l_image;
}

Ref<Image> Video::next_frame(){
	Ref<Image> l_image = memnew(Image);

	if (!is_open){
		UtilityFunctions::printerr("Video not yet open!");
		return l_image;
	}
   /*
		//set the seeker to the begining
	response = av_seek_frame(av_format_ctx, av_stream_video->index, 0, AVSEEK_FLAG_FRAME | AVSEEK_FLAG_ANY);
	avcodec_flush_buffers(av_codec_ctx_video);
	if (response < 0){
		UtilityFunctions::printerr("VCan't seek video to beginning!");
		return l_image;
	}
	*/
		

	av_packet = av_packet_alloc();
	av_frame = av_frame_alloc();
	
	while(true){
		//Demux the video
		response = av_read_frame(av_format_ctx, av_packet);
		if (response != 0){
			av_packet_unref(av_packet);
			//UtilityFunctions::printerr("Could not read frame");
			break;
		}

		if (av_packet->stream_index != av_stream_video->index){
			av_packet_unref(av_packet);
			continue;
		}

		//send packet for decoding
		response = avcodec_send_packet(av_codec_ctx_video, av_packet);
		if (response!=0){ 
			av_packet_unref(av_packet);
			break;}

		//valid packet found, decode frame
		while(true){
			//receive all frames
			response = avcodec_receive_frame(av_codec_ctx_video, av_frame);
			if (response != 0){
				av_frame_unref(av_frame);
				//UtilityFunctions::printerr("av_codec could not receive frame");
				break;
			}

			uint8_t* l_dest_data[1] = {byte_array.ptrw()};
			sws_scale(sws_ctx, av_frame->data, av_frame->linesize, 0, av_frame->height, l_dest_data, src_linesize);
			//the tutorial sets this to av_frame-> width/height, but that shows 0.
			l_image->set_data(av_frame->width, av_frame->height, 0, l_image->FORMAT_RGB8, byte_array);
			//UtilityFunctions::printerr("av_frame: ", av_frame->width, av_frame->height);
			//UtilityFunctions::printerr("image:", l_image->get_width(), l_image->get_height());
			//UtilityFunctions::printerr("av_codec_ctx context: ", av_codec_ctx_video->width, av_codec_ctx_video->height);
			av_frame_unref(av_frame);
			av_frame_free(&av_frame);
			av_packet_free(&av_packet);

			return l_image;

		}
		
		

		
	}
	
	//cleanup
	av_frame_free(&av_frame);
	av_packet_free(&av_packet);

	return l_image;
}

void Video::_get_total_frame_nr(){




	if (av_stream_video->nb_frames > 500){ 
		total_frame_nr = av_stream_video->nb_frames - 30;}
	
	av_packet = av_packet_alloc();
	av_frame = av_frame_alloc();

	frame_timestamp = (long)(total_frame_nr * average_frame_duration);

	//Video Seeking
	response = av_seek_frame(av_format_ctx, -1, start_time_video+frame_timestamp, AVSEEK_FLAG_FRAME | AVSEEK_FLAG_BACKWARD);
	avcodec_flush_buffers(av_codec_ctx_video);
	if (response < 0){
		UtilityFunctions::printerr("VCan't seek video stream!");
		av_frame_free(&av_frame);
		av_packet_free(&av_packet);
		
	}

	while(true){
		//Demux the video
		response = av_read_frame(av_format_ctx, av_packet);
		if (response != 0){
			av_packet_unref(av_packet);
			//UtilityFunctions::printerr("Could not read frame");
			break;
		}

		if (av_packet->stream_index != av_stream_video->index){
			av_packet_unref(av_packet);
			continue;
		}

		//send packet for decoding
		response = avcodec_send_packet(av_codec_ctx_video, av_packet);
		if (response!=0){ 
			av_packet_unref(av_packet);
			break;}

		//valid packet found, decode frame
		while(true){
			//receive all frames
			response = avcodec_receive_frame(av_codec_ctx_video, av_frame);
			if (response != 0){
				av_frame_unref(av_frame);
				break;
			}

			current_pts = av_frame-> best_effort_timestamp == AV_NOPTS_VALUE ? av_frame->pts : av_frame->best_effort_timestamp;
			if (current_pts == AV_NOPTS_VALUE){
				av_frame_unref(av_frame);
				continue;
			}

			//skip to requested frame
			if ((long)(current_pts * stream_time_base_video) / 10000 < frame_timestamp / 10000){
				av_frame_unref(av_frame);
				continue;
			}
			//av_frame_unref(av_frame);
			//av_frame_free(&av_frame);
			//av_packet_free(&av_packet);
			total_frame_nr++;

		}
		
		

		
	}

	//cleanup
	//av_frame_free(&av_frame);
	//av_packet_free(&av_packet);
	
	
}