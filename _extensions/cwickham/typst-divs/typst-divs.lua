function starts_with_typst(str)
  return string.sub(str, 1, 6) == "typst_"
end

function after_typst(str)
  local prefix = "typst_"
  return string.sub(str, #prefix + 1)
end

if not quarto.doc.is_format('typst') then
  function Div(el)
    if starts_with_typst(el.classes[1]) then
      return el.content
    end
  end
end


if quarto.doc.is_format('typst') then
  function Div(el)
    if starts_with_typst(el.classes[1]) then
      local fun_name = after_typst(el.classes[1])
      local preamble = pandoc.Blocks({})
      local postamble = pandoc.Blocks({})
      preamble:insert(pandoc.RawBlock('typst', '#' .. fun_name .. '('))
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
  end
end