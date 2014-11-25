class WebglTestGame < Game
  def setup
    display.clear_color = Color[100, 200, 200]
  end

  def update(elapsed)
    display.preframe

    display.fill_color = Color[200, 100, 100]
    display.fill_rectangle(50, 50, 50, 100)
    display.fill_rectangle(display.width - 100, display.height - 150, 50, 100)
  end
end
