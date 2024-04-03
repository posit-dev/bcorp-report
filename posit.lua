function Div(el)
  if el.classes:includes('page-blue') then
    local blocks = pandoc.List({
      pandoc.RawBlock('typst', '#page_blue()[')
    })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock('typst', ']\n'))
    return blocks
  end
end