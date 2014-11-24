module Yeah
module Web
class FallbackDisplay
  attr_reader :text_font, :text_size

  def initialize(options = {})
    canvas_selector = options.fetch(:canvas_selector, DEFAULT_CANVAS_SELECTOR)

    @canvas = `document.querySelectorAll(#{canvas_selector})[0]`
    @context = `#@canvas.getContext('2d')`
    self.text_font = Font['']
    self.text_size = DEFAULT_DISPLAY_TEXT_SIZE
    self.size = options.fetch(:size, nil)
    @transform = [1, 0, 0, 1, 0, 0]
    @transforms = []

    `DISPLAY = #{self}`
  end

  def width
    `#@canvas.width`
  end
  def width=(value)
    @width = value
    `#@canvas.width = #{value}` unless value.nil?

    font = "#{@text_size}px \"#{@text_font.path}\""
    `#@context.font = #{font}`
  end

  def height
    `#@canvas.height`
  end
  def height=(value)
    @height = value
    `#@canvas.height = #{value}` unless value.nil?

    font = "#{@text_size}px \"#{@text_font.path}\""
    `#@context.font = #{font}`
  end

  def size
    [`#@canvas.width`, `#@canvas.height`]
  end
  def size=(value)
    @width, @height = value

    unless value.nil?
      `#@canvas.width = #{value[0]}`
      `#@canvas.height = #{value[1]}`
    end

    font = "#{@text_size}px \"#{@text_font.path}\""
    `#@context.font = #{font}`
  end

  def fill_color
    Color[`#@context.fillStyle`]
  end
  def fill_color=(color)
    `#@context.fillStyle = #{color.to_hex}`
  end

  def stroke_color
    Color[`#@context.strokeStyle`]
  end
  def stroke_color=(color)
    `#@context.strokeStyle = #{color.to_hex}`
  end

  def stroke_width
    `#@context.lineWidth`
  end
  def stroke_width=(numeric)
    `#@context.lineWidth = #{numeric}`
  end

  def text_font=(font)
    @text_font = font

    font = "#{@text_size}px \"#{@text_font.path}\""
    `#@context.font = #{font}`
  end

  def text_size=(size)
    @text_size = size

    font = "#{@text_size}px \"#{@text_font.path}\""
    `#@context.font = #{font}`
  end

  def color_at(x, y)
    data = `#@context.getImageData(#{x}, #{y}, 1, 1).data`
    Color[`data[0]`, `data[1]`, `data[2]`]
  end

  def translate(x, y)
    @transform[4] += `#{@transform[0]} * #{x} + #{@transform[2]} * #{y}`
    @transform[5] += `#{@transform[1]} * #{x} + #{@transform[3]} * #{y}`

    %x{
      #@context.setTransform(#{@transform[0]}, #{@transform[1]},
                             #{@transform[2]}, #{@transform[3]},
                             #{@transform[4]}, #{@transform[5]}); }
  end

  def translate_x(x)
    @transform[4] += `#{@transform[0]} * #{x} + #{@transform[2]}`
    @transform[5] += `#{@transform[1]} * #{x} + #{@transform[3]}`

    %x{
      #@context.setTransform(#{@transform[0]}, #{@transform[1]},
                             #{@transform[2]}, #{@transform[3]},
                             #{@transform[4]}, #{@transform[5]}); }
  end

  def translate_y(y)
    @transform[4] += `#{@transform[0]} + #{@transform[2]} * #{y}`
    @transform[5] += `#{@transform[1]} + #{@transform[3]} * #{y}`

    %x{
      #@context.setTransform(#{@transform[0]}, #{@transform[1]},
                             #{@transform[2]}, #{@transform[3]},
                             #{@transform[4]}, #{@transform[5]}); }
  end

  def scale(x, y)
    %x{
      #{@transform} = [#{@transform[0]} * #{x},
                       #{@transform[1]} * #{x},
                       #{@transform[2]} * #{y},
                       #{@transform[3]} * #{y},
                       #{@transform[4]}, #{@transform[5]}];

      #@context.setTransform(#{@transform[0]}, #{@transform[1]},
                             #{@transform[2]}, #{@transform[3]},
                             #{@transform[4]}, #{@transform[5]}); }
  end

  def scale_x(x)
    %x{
      #{@transform} = [#{@transform[0]} * #{x},
                       #{@transform[1]} * #{x},
                       #{@transform[2]}, #{@transform[3]},
                       #{@transform[4]}, #{@transform[5]}];

      #@context.setTransform(#{@transform[0]}, #{@transform[1]},
                             #{@transform[2]}, #{@transform[3]},
                             #{@transform[4]}, #{@transform[5]}); }
  end

  def scale_y(y)
    %x{
      #{@transform} = [#{@transform[0]}, #{@transform[1]},
                       #{@transform[2]} * #{y},
                       #{@transform[3]} * #{y},
                       #{@transform[4]}, #{@transform[5]}];

      #@context.setTransform(#{@transform[0]}, #{@transform[1]},
                             #{@transform[2]}, #{@transform[3]},
                             #{@transform[4]}, #{@transform[5]}); }
  end

  def rotate(radians)
    %x{
      var cos = Math.cos(#{radians}),
          sin = Math.sin(#{radians}),
          e0 = #{@transform[0]} * cos + #{@transform[2]} * sin,
          e1 = #{@transform[1]} * cos + #{@transform[3]} * sin,
          e2 = #{@transform[0]} * -sin + #{@transform[2]} * cos,
          e3 = #{@transform[1]} * -sin + #{@transform[3]} * cos;

      #@transform = [e0, e1, e2, e3, #{@transform[4]}, #{@transform[5]}];

      #@context.setTransform(#{@transform[0]}, #{@transform[1]},
                             #{@transform[2]}, #{@transform[3]},
                             #{@transform[4]}, #{@transform[5]}); }
  end

  def push
    @transforms.push(@transform.dup)
  end

  def pop
    @transform = @transforms.pop

    %x{
      #@context.setTransform(#{@transform[0]}, #{@transform[1]},
                             #{@transform[2]}, #{@transform[3]},
                             #{@transform[4]}, #{@transform[5]}); }
  end

  def stroke_line(start_x, start_y, end_x, end_y)
    %x{
      #@context.beginPath();
      #@context.moveTo(#{start_x}, #{start_y});
      #@context.lineTo(#{end_x}, #{end_y});
      #@context.closePath();
      #@context.stroke();
    }
  end

  def stroke_curve(start_x, start_y, end_x, end_y, control_x, control_y)
    %x{
      #@context.beginPath();
      #@context.moveTo(#{start_x}, #{start_y});
      #@context.quadraticCurveTo(#{control_x}, #{control_y},
                                 #{end_x}, #{end_y});
      #@context.closePath();
      #@context.stroke();
    }
  end

  def stroke_curve2(start_x, start_y, end_x, end_y, control1_x, control1_y, control2_x, control2_y)
    %x{
      #@context.beginPath();
      #@context.moveTo(#{start_x}, #{start_y});
      #@context.bezierCurveTo(#{control1_x}, #{control1_y},
                              #{control2_x}, #{control2_y},
                              #{end_x}, #{end_y});
      #@context.closePath();
      #@context.stroke();
    }
  end

  def stroke_rectangle(x, y, width, height)
    `#@context.strokeRect(#{x}, #{y}, #{width}, #{height})`
  end

  def fill_rectangle(x, y, width, height)
    `#@context.fillRect(#{x}, #{y}, #{width}, #{height})`
  end

  def stroke_ellipse(center_x, center_y, radius_x, radius_y)
    %x{
      #@context.beginPath();
      #@context.save();
      #@context.beginPath();
      #@context.translate(#{center_x} - #{radius_x},
                          #{center_y} - #{radius_y});
      #@context.scale(#{radius_x}, #{radius_y});
      #@context.arc(1, 1, 1, 0, 2 * Math.PI, false);
      #@context.restore();
      #@context.stroke();
    }
  end

  def fill_ellipse(center_x, center_y, radius_x, radius_y)
    %x{
      #@context.beginPath();
      #@context.save();
      #@context.beginPath();
      #@context.translate(#{center_x} - #{radius_x},
                          #{center_y} - #{radius_y});
      #@context.scale(#{radius_x}, #{radius_y});
      #@context.arc(1, 1, 1, 0, 2 * Math.PI, false);
      #@context.restore();
      #@context.fill();
    }
  end

  def clear
    `#@context.fillRect(0, 0, #{width}, #{height})`
  end

  def begin_shape
    `#@context.beginPath()`
  end

  def end_shape
    `#@context.closePath()`
  end

  def move_to(x, y)
    `#@context.moveTo(#{x}, #{y})`
  end

  def line_to(x, y)
    `#@context.lineTo(#{x}, #{y})`
  end

  def curve_to(x, y, control_x, control_y)
    `#@context.quadraticCurveTo(#{control_x}, #{control_y},
                                #{x}, #{y})`
  end

  def curve2_to(x, y, control1_x, control1_y, control2_x, control2_y)
    `#@context.bezierCurveTo(#{control1_x}, #{control1_y},
                             #{control2_x}, #{control2_y},
                             #{x}, #{y})`
  end

  def stroke_shape
    `#@context.stroke()`
  end

  def fill_shape
    `#@context.fill()`
  end

  def draw_image(image, x, y)
    `#@context.drawImage(#{image.to_n}, #{x}, #{y})`
  end

  def draw_image_cropped(image, x, y, crop_x, crop_y, crop_width, crop_height)
    %x{#@context.drawImage(#{image.to_n},
                           #{crop_x}, #{crop_y},
                           #{crop_width}, #{crop_height},
                           #{x}, #{y},
                           #{crop_x}, #{crop_y})}
  end

  def fill_text(text, x, y)
    `#@context.fillText(#{text}, #{x}, #{y})`
  end

  def stroke_text(text, x, y)
    `#@context.strokeText(#{text}, #{x}, #{y})`
  end

  private

  def scale_to_window
    %x{
      var canvas = document.getElementsByTagName('canvas')[0];

      if (#{@width.nil?} && #{@height.nil?}) {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        canvas.setAttribute('style', "");
      } else {
        var widthScale = window.innerWidth / canvas.width,
            heightScale = window.innerHeight / canvas.height;
        window.displayScale = Math.min(widthScale, heightScale);

        if (PRESERVE_PIXELS && displayScale >= 1) {
          displayScale = Math.floor(displayScale);
        }

        var width = canvas.width * displayScale,
            height = canvas.height * displayScale,
            sizeStyle = "width:"+width+"px; height:"+height+"px";

        canvas.setAttribute('style', sizeStyle);
      }
    }

    font = "#{@text_size}px \"#{@text_font.path}\""
    `#@context.font = #{font}`
  end
end
end
end
