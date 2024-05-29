if (quarto.doc.is_format('html') or quarto.doc.is_format('markdown')) then
  function Div(el)
    if el.classes:includes('page-blue') or 
      el.classes:includes('cols-2') or 
      el.classes:includes('banner') or
      el.classes:includes('back-page') then
      return el.content
    end
  end
end