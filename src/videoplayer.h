#ifndef VIDEOPLAYER_H
#define VIDEOPLAYER_H

#include <godot_cpp/classes/control.hpp>

namespace godot {

class VideoPlayer : public Control {
	GDCLASS(VideoPlayer, Control)

private:
	double time_passed;

protected:
	static void _bind_methods();

public:
	VideoPlayer();
	~VideoPlayer();

	void _process(double delta) override;
};

}

#endif