void DrawCursorAt(Vec2f position, string& in filename)
{
	position = getMap().getAlignedWorldPos(position);
	
	if (position == Vec2f_zero) return;
	
	Driver@ driver = getDriver();
	
	position = driver.getScreenPosFromWorldPos(position - Vec2f(1, 1));
	float h = driver.getScreenHeight();
	float w = driver.getScreenWidth();
	float w_factor = w / 1280;
	float h_factor = h / 1024;
	float scale_factor = w * w_factor / h * h_factor;

	GUI::DrawIcon(filename, position, getCamera().targetDistance * scale_factor);
}