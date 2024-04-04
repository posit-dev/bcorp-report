function Div(el)
  if el.classes:includes('page-blue') then
    local blocks = pandoc.List({
      pandoc.RawBlock('typst', '#page_blue()[')
    })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock('typst', ']\n'))
    return blocks
  end
  if el.classes:includes('cols-2') then
    local blocks = pandoc.List({
      pandoc.RawBlock('typst', '#col-2()[')
    })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock('typst', ']\n'))
    return blocks
  end
  if el.classes:includes('banner') then
    local blocks = pandoc.List({
      pandoc.RawBlock('typst', '#banner()[')
    })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock('typst', ']\n'))
    return blocks
  end
end
