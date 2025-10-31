#ifndef VIDEO_H
#define VIDEO_H

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/audio_stream_wav.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/image.hpp>

#include <cstdint>
#include <vector>
 
extern "C" {
	#include <libavcodec/avcodec.h>
	#include <libavformat/avformat.h>
	#include <libavdevice/avdevice.h>
	#include <libavutil/dict.h>
	#include <libavutil/channel_layout.h>
	#include <libavutil/opt.h>
	#include <libavutil/imgutils.h>
	#include <libavutil/pixdesc.h>
	#include <libswscale/swscale.h>
	#include <libswresample/swresample.h>
}
	

namespace godot {

class Video : public Object {
	GDCLASS(Video, Object);

private:
	AVFormatContext* av_format_ctx;
	AVStream* av_stream_video;
	AVStream* av_stream_audio;
	AVCodecContext* av_codec_ctx_video;
	AVCodecContext* av_codec_ctx_audio;

	AVFrame* av_frame;
	AVPacket* av_packet;

	struct SwsContext* sws_ctx;
	struct SwrContext* swr_ctx;

	PackedByteArray byte_array; // for video frames

	int response; 
	int src_linesize[4]; //how much data in a horizontal line of video
	int total_frame_nr;

	long start_time_video;
	long start_time_audio;
	long frame_timestamp;
	long current_pts;

	double average_frame_duration = 0;
	double stream_time_base_video;
	double stream_time_base_audio;


protected:
	static void _bind_methods();

	bool is_open;

public:
	Video();
	~Video();

	void open_video(String _path);
	void close_video();

	Ref<Image> seek_frame(int a_frame_nr);
	Ref<Image> next_frame();

	Ref<AudioStreamWAV> get_audio();

	inline float get_avg_framerate(){return av_q2d(av_stream_video->avg_frame_rate);}
	inline float get_r_framerate(){return av_q2d(av_stream_video->r_frame_rate);}
	inline int get_total_frame_nr() {return total_frame_nr;}
	void _get_total_frame_nr();

	void print_av_error(const char* a_message);
};

}

#endif