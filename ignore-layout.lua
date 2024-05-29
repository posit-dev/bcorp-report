if not quarto.doc.is_format('typst') then
  function Div(el)
    if el.classes:includes('page-blue') or 
      el.classes:includes('cols-2') or 
      el.classes:includes('page-banner') or
      el.classes:includes('back-page') then
      return el.content
    end
  end
end