require 'axlsx'
require 'delorean_lang'

class Marty::Xl
  include Delorean::Model

  def self.spreadsheet(worksheets)
    xl = Marty::Xl.new(worksheets)
    xl.package
  end

  def deep_copy(value)
    return value.each_with_object({}){|(k, v), h| h[k] = deep_copy(v)} if
      value.is_a?(Hash)

    value.is_a?(Array) ? value.map{|v| deep_copy(v)} : value
  end

  def merge_cell_edges(a, b)
    return b unless a.kind_of?(Hash) && b.kind_of?(Hash)

    a_border, b_border = a[:border], b[:border]

    return b unless a_border.is_a?(Hash) && a_border[:edges].is_a?(Array)

    non_match = a_border.detect {
      |key, value|
      key != :edges && b_border[key] != value
    }

    a_border[:edges].each do |edge|
      unless b_border[:edges].include? edge
        # add new edges:
        b_border[:edges] << edge

        # add new style/color for the new edge if there is no style
        # match with the old edges:
        b["border_#{edge}".to_sym] = a_border.each_with_object({}) {
          |(key, value), h|
          h[key] = value unless key == :edges
        } if non_match
      end
    end
    b
  end

  def merge_row_edges(a, b)
    return b unless a.count > 0
    a.each_index do |ind|
      b[ind] = merge_cell_edges(a[ind], deep_copy(b[ind]))
    end
    b
  end

  def bordered_cells(a, b)
    a.each_index do |c|
      a[c] = merge_cell_edges(b[c], deep_copy(a[c])) if a[c] && b[c]
      b[c] = a[c] unless a[c].nil?
    end
    b.each_index { |el| b[el] = {} unless b[el] }
  end

  def position_row(d, column_offset, r_number, rows, styles, row_styles)
    rows[r_number] ||= []
    styles[r_number] ||= []
    row_styles[r_number] ||= {}

    new_row, new_style = rows[r_number], styles[r_number]

    (0...column_offset).each do |t|
      new_row[t] ||= ""
      new_style[t] ||= {}
    end

    d[1].each_index do |c_index|
      new_row[c_index+column_offset] = d[1][c_index]
    end if d[1].kind_of?(Array)

    if (d.length > 2) && d[2].kind_of?(Hash) && d[2]["style"].kind_of?(Array)
      d[2]["style"].each_index do |c_index|
        new_style[c_index+column_offset] = d[2]["style"][c_index]
      end
    end

    # apply style for the row as a whole:
    if (d.length > 2) && d[2].kind_of?(Hash)
      d[2].each do |key, value|
        unless key == :style.to_s
          row_styles[r_number][key] = value
        else
          # skip if the style is an array: /style as an array is
          # handled by the 'apply a style to each cell' section/
          next unless value.kind_of?(Hash)
          d[1].length.times do |t|
            new_style[t+column_offset] = value
          end
        end
      end
    end
    # row data, style:
    rows[r_number], styles[r_number] = new_row, new_style
  end

  def position_elem(d, offset, last_row, el)
    x1, y1, x2, y2, w, h = d[1]
    column_offset, row_offset = offset

    y_coords = y2.is_a?(Fixnum) || d[0] != "image" ? [y1, y2] : [y1]
    x_coords = x2.is_a?(Fixnum) || d[0] != "image" ? [x1, x2] : [x1]

    # add the row offset:
    y1, y2 = y_coords.map { |y|
      if y.is_a?(Fixnum)
        row_offset + y
      elsif y.is_a?(Hash) && y["off"].is_a?(Fixnum)
        last_row + y["off"]
      else
        raise "bad offset #{y}"
      end
    }

    # add the column offset:
    x1, x2 = x_coords.map { |x|
      raise "bad range point #{x}" unless x.is_a? Fixnum
      column_offset + x
    }

    el[last_row] = [] unless
      el[last_row] || ["border", "image"].member?(d[0])

    case d[0]
    when "conditional_formatting"
      el[last_row] << [d[0], [x1, y1, x2, y2], d[2]]
    when "merge"
      el[last_row] << [d[0], [x1, y1, x2, y2]]
    when "border"
      el << [d[0], [x1, y1, x2, y2], d[2]]
    when "image"
      el << [d[0], [x1, y1, x2, y2, w, h], d[2]]
    end
  end

  def position_borders(borders)
    b_styles  = []
    borders.each do |b|
      top_row, middle_row, bottom_row, edge_h = [], [], [], {}
      br, range, defaults = b
      col0, row0, colw, rowh = range

      raise "wrong border range #{range}" if
        col0 > colw || row0 > rowh || (col0 == colw && row0 == rowh)

      defaults = self.class.symbolize_keys(defaults, ':')

      boxborders = Hash.new do |hash, key|
        hash[key] = {
          border: defaults.merge( {edges: key.to_s.split('_').map(&:to_sym)} )
        }
      end

      boxborders[:nil] = {}

      tro, mro, bro =
        top_row.object_id, middle_row.object_id, bottom_row.object_id

      if col0 == colw
        # vertical line
        edge_h[tro], edge_h[mro], edge_h[bro] =
          ["left"], ["left"], ["left"]
      elsif row0 == rowh
        # horizontal line
        edge_h[tro], edge_h[mro], edge_h[bro] =
          ["top"]*3, ["top"]*3, ["top"]*3
      else
        # box
        edge_h[tro] = ["top_left", "top_right", "top"]
        edge_h[mro] = ["left", "right", "nil"]
        edge_h[bro] = ["bottom_left", "bottom_right", "bottom"]
      end

      [top_row, middle_row, bottom_row].each do |r|
        if col0 == colw
          r[col0] = boxborders[edge_h[r.object_id][0].to_sym]
        else
          (col0...colw).each do |counter|
            a = (counter == col0) ? boxborders[edge_h[r.object_id][0].to_sym] : {}

            # counter == col0 == (colw - 1) => merge the edges:
            a = boxborders[edge_h[r.object_id][1].to_sym] =
              merge_cell_edges(a, deep_copy(boxborders[edge_h[r.object_id][1].to_sym])) if
              counter == (colw - 1)

            a = boxborders[edge_h[r.object_id][2].to_sym] unless
              counter == col0 || counter == (colw - 1)

            r[counter] = a
          end
        end
      end

      if row0 == rowh
        b_styles[row0] ||= []
        bordered_cells(top_row, b_styles[row0])
      else
        (row0...rowh).each_with_index do |r, i|
          b_styles[r] ||= []

          a = i == 0 ? top_row : []

          a = merge_row_edges(a,bottom_row) if
            i == (rowh - row0 - 1)

          a = middle_row unless
            i == 0 || i == (rowh - row0 - 1)

          bordered_cells(a, b_styles[r])
        end
      end
    end

    b_styles
  end

  def worksheet_rows(ws, rows, styles, row_styles, format, borders, images)
    wsrows = []

    b_styles = position_borders(borders)
    rlenmax = rows.map { |el| el.kind_of?(Array) ? el.length : 0 }.max

    rows.each_with_index do |r, index|
      rlen = r.kind_of?(Array) ? r.length : 0

      if rlen < rlenmax
        rows[index] ||= []
        rows[index] += [""] * (rlenmax-rlen)
      end

      row_styles[index] ||= {}

      rsi = row_styles[index]

      rsi["style"] = styles[index].kind_of?(Array) ? styles[index] : []

      if b_styles[index].kind_of?(Array) && b_styles[index].count > 0
        len = [rsi["style"].count, b_styles[index].count].max

        len.times do |ind|
          b_styles[index][ind] ||= {}
          rsi["style"][ind] ||= {}

          rsi["style"][ind] =
            rsi["style"][ind].merge(b_styles[index][ind])
        end

        rsi["style"] = rsi["style"].map{ |x| x || {} }
      end

      wsrows << ["row", rows[index], rsi]

      if format[index] && format[index].kind_of?(Array)
        format[index].each do |f|
          raise "wrong number of arguments for #{f[0]}" unless
            [
             ["conditional_formatting", 3],
             ["merge", 2]
            ].member?([f[0], f.length])

          wsrows << f
        end
      end

    end

    apply_relative_worksheet_ops(ws, wsrows + images)
  end

  attr_reader :styles, :package

  def initialize(worksheets)
    @styles = {}
    @package = Axlsx::Package.new
    wb = package.workbook

    # We got some sort of error if the worksheets is an array
    if worksheets.is_a? Hash
      ws = wb.add_worksheet(name: "EXCEPTION")
      ws.add_row ["error", worksheets["error"]]
      ws.add_row ["backtrace", worksheets["backtrace"]]
      return
    end

    raise "expected worksheets array, got: #{worksheets}" unless
      worksheets.is_a?(Array)

    worksheets << ["No data", []] if worksheets.count == 0

    worksheets.each { |opl|

      name, ops, opts = opl
      raise "bad worksheet name: #{name}" unless name.is_a?(String)
      raise "bad worksheet ops" unless ops.is_a?(Array)
      raise "bad options #{opts}" unless opts.is_a?(Hash) || opts.nil?

      # Remove special characters and truncate sheet name due to Excel
      # limitations.
      name = name.gsub(':', '').truncate(31)

      opts = self.class.symbolize_keys(opts || {}, ':')
      widths = opts[:widths] || []
      gridlines = opts[:gridlines] != 0

      ws = wb.add_worksheet(name: name)

      ws.column_widths(*widths) if widths.is_a?(Array) && widths.count > 0
      ws.sheet_view.show_grid_lines = gridlines

      apply_relative_worksheet_ops(ws, ops)
    }
    @package.use_shared_strings = true
  end

  def add_style(style)
    raise "bad style" unless style.is_a?(Hash) || style.is_a?(Array)

    if style.is_a?(Array)
      style.map { |s|
        styles[s] ||= package.workbook.styles.add_style(s)
      }
    else
      styles[style] ||= package.workbook.styles.add_style(style)
    end
  end

  def intern_range(ws, range)
    return range if range.is_a? String
    raise "bad range #{range}" unless range.is_a?(Array) && range.length==4
    x1, y1, x2, y2 = range

    y1, y2 = [y1, y2].map { |y|
      next y unless y.is_a?(Hash)
      raise "bad offset #{y}" unless y["off"].is_a?(Fixnum)
      ws.rows.last.index + y["off"]
    }

    [x1, y1, x2, y2].each { |x|
      raise "bad range point #{x}" unless x.is_a? Fixnum
    }
    Axlsx.cell_r(x1, y1) + ":" + Axlsx.cell_r(x2, y2)
  end

  def recalc_offsets(ops_pos)
    new_ops1, new_ops2, new_ops = [], [], []
    # precalculate the offsets of pos options embedded in another pos opt:
    ops_pos.each { |d|
      new_ops1 += d[2].select { |inner_ops|
        inner_ops if inner_ops[0] == "pos"
      }.map { |inner|
        [inner[0], d[1].zip(inner[1]).map { |x,y| x+y }, inner[2] ]
      }
    }
    # keep the offsets of non-pos options embedded in pos opt:
    new_ops2 = ops_pos.map { |d|
      [ d[0], d[1], d[2].select{|inner| inner if inner[0] != "pos" } ]
    }
    new_ops = new_ops1 + new_ops2
    count = new_ops.select { |d|
      d[2].select { |inner_ops|
        inner_ops if inner_ops[0] == "pos"
      }.count > 0
    }.count

    count == 0 ? new_ops.sort : recalc_offsets(new_ops)
  end

  def apply_relative_worksheet_ops(ws, ops)

    non_pos = ops.select {|opl| opl[0] != "pos" }
    ops_pos = ops.select {|opl| opl[0] == "pos" }
    ops_brd = ops.select {|opl| opl[0] == "border" }

    if (ops_pos.count > 0)
      # Wrap all non-pos options in a pos option with offset 0, 0:
      pos_00_ops = non_pos.count > 0 ? [ ["pos", [0, 0], non_pos] ] : []
      # Recalculate the offsets of embedded pos opts:
      ops =  pos_00_ops + recalc_offsets(ops_pos)
    elsif (ops_brd.count > 0)
      # Wrap the non-pos options in a pos opt with offset 0, 0:
      pos_00_ops = [ ["pos", [0, 0], non_pos] ]
      ops = pos_00_ops
    end

    rows, styles, row_styles, format, borders, images = [], [], [], [], [], []
    ops.each { |opl|
      raise "bad op #{opl}" unless opl.length > 1
      case opl[0]
      when "pos"
        op, offset, data = opl
        raise "bad offset #{offset}" unless
          offset.is_a?(Array) && offset.length == 2 &&
          offset.all? {|x| x.is_a? Fixnum}
        # column offset, row offset:
        column_offset, row_offset = offset
        r_number, last_row = row_offset, row_offset

        data.each do |d|
          raise "non array data #{d[1]}" unless d[1].is_a?(Array)
          raise "non hash data options #{d[2]}" unless
            [NilClass, Hash, String, Array].member? d[2].class
          case d[0]
          when "row"
            position_row(d, column_offset, r_number, rows, styles, row_styles)
            last_row = r_number
            r_number += 1
          when "conditional_formatting", "merge"
            position_elem(d, offset, last_row, format)
          when "border"
            position_elem(d, offset, last_row, borders)
          when "image"
            position_elem(d, offset, last_row, images)
          else
            raise "unknown op #{d[0]} embedded in 'position' option"
          end
        end

      when "row"
        op, data, options = opl

        raise "bad row op #{opl}" unless data.is_a?(Array) || opl.length > 3
        raise "non hash options #{options} for row" unless
          options.nil? || options.is_a?(Hash)

        options = self.class.symbolize_keys(options || {}, ':')

        options[:style] = add_style(options[:style]) if options[:style]

        ws.add_row data, options

      when "row_style"
        op, row_num, style = opl

        # FIXME: need to handle Array?
        raise "non hash arg for row_style" unless style.is_a?(Hash)
        raise "bad row num #{opl}" unless row_num.is_a?(Fixnum)

        style = self.class.symbolize_keys(style, ':')

        style_id = add_style(style)
        row = ws.rows[row_num]

        row.style = style_id

      when "merge"
        op, range = opl

        raise "bad merge op #{opl}" unless opl.length == 2
        range = intern_range(ws, range)

        ws.merge_cells range
      when "conditional_formatting"
        op, range, format = opl

        raise "non hash arg for format" unless format.is_a?(Hash)

        range = intern_range(ws, range)

        format = self.class.symbolize_keys(format, ':')

        color_scale_a = format[:color_scale]

        if color_scale_a
          raise "color_scale must be an array" unless
            color_scale_a.is_a?(Array)

          raise "non-hash color_scale element" unless
            color_scale_a.all? {|x| x.is_a?(Hash)}

          format[:color_scale] = Axlsx::ColorScale.new(*color_scale_a)
        end

        dxfid = format[:dxfId]
        format[:dxfId] = add_style(dxfid) if dxfid.is_a?(Hash)

        ws.add_conditional_formatting(range, format)
      when "image"
        op, range, img = opl
        raise "bad image params #{range}" unless
          range.is_a?(Array) && range.length == 6
        x1, y1, x2, y2, w, h = range
        raise "bad image range, width or height #{range}" unless
          [ x1, y1, w, h ].all? {|x| x.is_a? Fixnum}
        ws.add_image(image_src: "#{Rails.public_path}/images/#{img}",
                     noSelect: true,
                     noMove: true) do |image|
          image.width 	= w
          image.height 	= h
          image.start_at x1, y1
          image.end_at x2, y2 if x2.is_a?(Fixnum) && y2.is_a?(Fixnum)
        end
      else
        raise "unknown op #{opl[0]}"
      end
    }
    worksheet_rows(ws,rows,styles,row_styles,format,borders,images) unless
      [ops_pos.count, ops_brd.count].all?{ |a| a == 0 }
  end

  # recursive symbolize_keys. FIXME: this belongs in a generic
  # library somewhere.
  def self.symbolize_keys(obj, sym_str=nil)
    case obj
    when Array
      obj.map {|x| symbolize_keys(x, sym_str)}
    when Hash
      obj.inject({}) { |result, (key, value)|
        key = key.to_sym if key.is_a?(String)
        result[key] = symbolize_keys(value, sym_str)
        result
      }
    when String
      (sym_str && obj.starts_with?(sym_str)) ? obj[sym_str.length..-1].to_sym : obj
    else
      obj
    end
  end

end
