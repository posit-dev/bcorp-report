function Div(el)
  if el.classes:includes('page-blue') then
    local blocks = pandoc.List({
      pandoc.RawBlock('typst', '#page_blue()[')
    })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock('typst', ']\n'))
    return blocks
  end
  if el.classes:includes('page-banner') then
    --- based on: https://github.com/quarto-dev/quarto-cli/blob/db5ba169cb89abab1ff0fb31abb69d8d021e12f8/src/resources/filters/quarto-post/typst.lua#L32
    el.classes = el.classes:filter(function(c) return c ~= "page-banner" end)
    local preamble = pandoc.Blocks({})
    local postamble = pandoc.Blocks({})
    preamble:insert(pandoc.RawBlock("typst", "#page_banner("))
    for k, v in pairs(el.attributes) do
      preamble:insert(pandoc.RawBlock("typst", k .. ":" .. v .. ",\n"))
    end
    preamble:insert(pandoc.RawBlock("typst", "[\n"))
    postamble:insert(pandoc.RawBlock("typst", "])\n\n"))

    local result = pandoc.Blocks({})
    result:extend(preamble)
    result:extend(el.content)
    result:extend(postamble)
    return result
  end
  if el.classes:includes('cols-2') then
    local blocks = pandoc.List({
      pandoc.RawBlock('typst', '#col-2()[')
    })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock('typst', ']\n'))
    return blocks
  end
  if el.classes:includes('back-page') then
    local blocks = pandoc.List({
      pandoc.RawBlock('typst', '#back_page()[')
    })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock('typst', ']\n'))
    return blocks
  end
end
