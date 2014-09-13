class DisplayTest < Test
  def setup
    @object = Display.new
  end

  def test_implements_display_interface
    methods = %i[color_at push pop stroke_line stroke_rectangle fill_rectangle
      stroke_ellipse fill_ellipse clear begin_shape end_shape move_to line_to
      curve_to curve2_to stroke_shape fill_shape image image_cropped fill_text
      stroke_text]
    methods.each { |m| assert_respond_to(@object, m) }

    transform_methods = %i[translate scale rotate]
    transform_methods.each do |transform_method|
      assert_respond_to(@object, transform_method)
      assert_respond_to(@object, "#{transform_method}_x")
      assert_respond_to(@object, "#{transform_method}_y")
      assert_respond_to(@object, "#{transform_method}_z")
    end

    attributes = %i[size width height fill_color stroke_color stroke_width
      text_font text_size]
    attributes.each do |attribute|
      assert_respond_to(@object, attribute)
      assert_respond_to(@object, "#{attribute}=")
    end
  end

  def test_color_at_gets_color_at_position
    position = V[5, 5]

    @object.fill_color = C[0, 128, 255]
    @object.fill_rectangle(position, V[1, 1])

    assert_equal(@object.fill_color, @object.color_at(position))
  end

  def test_fill_rectangle_fills_area_with_fill_color
    position = V[100, 200]
    size = V[100, 100]

    @object.fill_color = C[255, 128, 0]
    @object.fill_rectangle(position, size)

    top_left = position
    middle = position + size / 2
    bottom_right = position + size - V[1, 1]

    [top_left, middle, bottom_right].each do |position|
      assert_equal(@object.fill_color, @object.color_at(position))
    end
  end
end