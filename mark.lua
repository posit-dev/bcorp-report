function Span(el)
  if el.classes:includes('mark') then 
    local inlines = pandoc.List({
      pandoc.RawInline('typst', '#mark()[')
    })
    inlines:extend(el.content)
    inlines:insert(pandoc.RawInline('typst', ']\n'))
    return inlines
  end
end