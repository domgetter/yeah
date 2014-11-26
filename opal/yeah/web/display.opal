module Yeah
module Web
class Display
  attr_reader :gl, :fill_color
  attr_accessor :clear_color

  VERTEX_SHADER = <<-glsl
    attribute vec2 a_position;

    uniform vec2 u_display_size;
    uniform mat4 u_transformation;

    void main(void) {
      vec2 clipspace = a_position / u_display_size * 2.0 - 1.0;

      gl_Position = u_transformation * vec4(a_position, 1, 1) * vec4(1, -1, 1, 1);
    }
  glsl

  FRAGMENT_SHADER = <<-glsl
    precision mediump float;

    uniform vec4 u_color;

    void main(void) {
      gl_FragColor = u_color;
    }
  glsl

  def initialize(options = {})
    canvas_selector = options.fetch(:canvas_selector, DEFAULT_CANVAS_SELECTOR)

    @canvas = `document.querySelectorAll(#{canvas_selector})[0]`
    @gl = `#@canvas.getContext('webgl')`

    @clear_color = Color.new(0, 0, 0)

    setup_shaders

    `DISPLAY = #{self}`
  end

  def width
    `#@canvas.width`
  end
  def width=(value)
    @width = value
    `#@canvas.width = #{value}` unless value.nil?
  end

  def height
    `#@canvas.height`
  end
  def height=(value)
    @height = value
    `#@canvas.height = #{value}` unless value.nil?
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
  end

  def fill_color=(color)
    %x{
      var val = #{color.value};

      #@gl.uniform4f(#@col_loc,
                      val[0] / 255.0, val[1] / 255.0, val[2] / 255.0, val[3]);
    }

    @fill_color = color
  end

  def fill_rectangle(x, y, width, height)
    %x{
      var res = #@gl.getUniformLocation(#@shader_program, 'u_resolution');
      #@gl.uniform2f(res, #@canvas.width, #@canvas.height);

      var posBuffer = #@gl.createBuffer();
      #@gl.bindBuffer(#@gl.ARRAY_BUFFER, posBuffer);
      var glVertices = new Float32Array([
        #{x}, #{y},
        #{x}, #{y} + #{height},
        #{x} + #{width}, #{y},
        #{x} + #{width}, #{y} + #{height}
      ]);
      #@gl.bufferData(#@gl.ARRAY_BUFFER, glVertices, #@gl.STATIC_DRAW);
      #@gl.vertexAttribPointer(#@pos_loc, 2, #@gl.FLOAT, false, 0, 0);

      #@gl.uniformMatrix4fv(#@trans_loc, false, #@transform);
      #@gl.drawArrays(#@gl.TRIANGLE_STRIP, 0, 4);
    }
  end

  def preframe
    %x{
      // Viewport
      #@gl.viewport(0, 0, #@canvas.width, #@canvas.height)

      // Clear
      #@gl.clearColor(#{@clear_color.value[0]} / 255.0,
                      #{@clear_color.value[1]} / 255.0,
                      #{@clear_color.value[2]} / 255.0, 1);
      #@gl.clear(#@gl.COLOR_BUFFER_BIT);
    }

    # Identity
    @transform = [1, 0, 0, 0,
                  0, 1, 0, 0,
                  0, 0, 1, 0,
                  0, 0, 0, 1]

    # Perspective
    t = @transform

    # Translate transform by (-1, -1, 0).
    t[12] = t[0] * -1 + t[4] * -1 + t[12]
    t[13] = t[1] * -1 + t[5] * -1 + t[13]
    t[14] = t[2] * -1 + t[6] * -1 + t[14]
    t[15] = t[3] * -1 + t[7] * -1 + t[15]

    # Scale transform by (2 / display.size).
    scale_x = `2 / #@canvas.width`
    scale_y = `2 / #@canvas.height`
    t[0] *= scale_x
    t[1] *= scale_x
    t[2] *= scale_x
    t[3] *= scale_x
    t[4] *= scale_y
    t[5] *= scale_y
    t[6] *= scale_y
    t[7] *= scale_y

    %x{
      #@gl.blendFunc(#@gl.SRC_ALPHA, #@gl.ONE_MINUS_SRC_ALPHA);
      #@gl.enable(#@gl.BLEND);
    }
  end

  def draw_image(image, x, y)
  end

private

  def setup_shaders
    @shader_program = `#@gl.createProgram()`

    %x{
      var vertexShader = #@gl.createShader(#@gl.VERTEX_SHADER);
      #@gl.shaderSource(vertexShader, #{VERTEX_SHADER});
      #@gl.compileShader(vertexShader);
      #@gl.attachShader(#@shader_program, vertexShader);

      var fragmentShader = #@gl.createShader(#@gl.FRAGMENT_SHADER);
      #@gl.shaderSource(fragmentShader, #{FRAGMENT_SHADER});
      #@gl.compileShader(fragmentShader);
      #@gl.attachShader(#@shader_program, fragmentShader);

      #@gl.linkProgram(#@shader_program);
      var link = #@gl.getProgramParameter(#@shader_program, #@gl.LINK_STATUS);
      if (!link) {
        var error = #@gl.getProgramInfoLog(#@shader_program);
        console.error("GL program link error:", error);
        return;
      }

      #@gl.useProgram(#@shader_program);
    }

    @pos_loc = `#@gl.getAttribLocation(#@shader_program, 'a_position')`
    `#@gl.enableVertexAttribArray(#@pos_loc)`

    @col_loc = `#@gl.getUniformLocation(#@shader_program, 'u_color')`

    @trans_loc = `#@gl.getUniformLocation(#@shader_program, 'u_transformation')`
  end

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
  end
end
end
end
