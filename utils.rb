def blend(col_a, col_b, alpha)
  newcol = []
  [0,1,2].each do |i|
    newcol[i] = (1.0 - alpha) * col_a[i] + alpha * col_b[i]
  end
  newcol
end

def color_to_triplet(color)
  color.slice(1,6).scan(/.{2}/).map { |x| x.hex.to_f / 255.0 }
end

def normalize_color(color, bg=nil)
  alpha = color.slice(7,9).to_i(16)
  if bg && (1..254).include?(alpha)
    bg = color_to_triplet(bg)
    color = color_to_triplet(color)
    result = blend(bg, color, alpha.to_f / 255.0)
    value = "%02x%02x%02x" % result.map { |x| (x*255.0).to_i }
  else
    value = color.slice(1,6).downcase
  end
  "\##{value}"
end