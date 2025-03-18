function colbreak()
  if quarto.doc.isFormat('typst') then
    return pandoc.RawBlock('typst', '#colbreak()')
  else
    return pandoc.Null()
  end
end