waterMarkEl        = null
uiEl               = null
button             = null
highlightContainer = null
highlightElements  = {}
currentElement		 = null
welcomeOverlay     = null
changes            = {}
token              = null
buttonColor        = "rgb(57, 221, 127)"
buttonHoverColor   = "rgb(10, 175, 80)"
buttonSaveColor    = "rgb(204, 211, 207)"

doctype = ->
  node = document.doctype;
  html = "<!DOCTYPE #{node.name}" +
         (node.publicId ? ' PUBLIC "' + node.publicId + '"' : '') +
         (!node.publicId && node.systemId ? ' SYSTEM' : '') +
         (node.systemId ? ' "' + node.systemId + '"' : '') +
         '>';

showWelcomeOverlay = ->
  src = "img/forklet-overlay.png"
  overlay = document.createElement("div")
  overlay.id = "forklet-overlay"
  img = document.createElement("img")
  img.src = src
  img.style.width = "100%"
  img.style.maxWidth = "870px"
  img.style.border = "none"
  img.style.outline = "none"
  img.style.display = "block"
  img.style.margin = "0 auto"
  overlay.appendChild(img)
  overlay.style.position   = "fixed"
  overlay.style.top        = "0px"
  overlay.style.width      = "100%"
  overlay.style.height     = "100%"
  overlay.style.background = "linear-gradient(rgba(15, 15, 15, 0.91), rgba(17, 16, 16, 0.78))"
  overlay.style.zIndex     = "99999"
  welcomeOverlay = overlay
  document.body.appendChild(overlay)
  overlay.addEventListener "click", ->
    document.body.removeChild(overlay)
    welcomeOverlay = null
  , false

# showWelcomeOverlay()

position = (element, top, left, width, height) ->
  element.style.top    = "#{top}px"
  element.style.left   = "#{left}px"
  element.style.width  = "#{width}px"
  element.style.height = "#{height}px"

uniqueSelector = (element) ->
  return unless element instanceof Element

  path = []
  while element && element.nodeType == Node.ELEMENT_NODE
    selector = element.nodeName.toLowerCase()
    if element.id
      selector += "#" + element.id
    else
      sibling = element
      nth = 1
      while sibling.nodeType == Node.ELEMENT_NODE && sibling = sibling.previousElementSibling
        nth++
      if nth > 1
        selector += ":nth-child(#{nth})"

    path.unshift(selector)
    if !element.id && (element.parentNode && element.parentNode != document.body)
      element = element.parentNode
    else
      element = null
  path.join(" > ")


addHighlightElements = ->
  highlightContainer = document.createElement("div")
  highlightContainer.display = "none"

  baseStyle = '''
    position: absolute;
    display: block;
    margin: 0;
    padding:0;
    border: 0;
    outline: 2px solid rgba(17,42,244,0.5);
  '''
  for id in ["lft", "rgt", "top", "bottom"]
    el = document.createElement("div")
    el.setAttribute("style", baseStyle)
    highlightContainer.appendChild(el)
    highlightElements[id] = el

  highlightElements["top"].style.outlineColor = "rgba(255,65,100,0.5)"
  highlightElements["rgt"].style.outlineColor = "rgba(0, 145, 247, 0.5)"
  highlightElements["bottom"].style.outlineColor = "rgba(255, 210, 70, 0.5)"
  highlightElements["lft"].style.outlineColor = "rgba(57, 221, 127, 0.5)"

  document.body.appendChild(highlightContainer)

coverElement = (element, container) ->
  rect = element.getBoundingClientRect()
  container.style.position = "absolute"
  position(container, rect.top + window.scrollY, rect.left + window.scrollX, rect.width, rect.height)

saveChanges = (cb) ->
  #if document.activeElement == currentElement
  #  blurHandler()

  return console.log("Saving selector: " + uniqueSelector(document.activeElement))
  #console.log("Saving changes %o", changes) unless token

  file = currentHTMLFile()

  waitForReadyToSave ->
    uiEl.parentNode.removeChild(uiEl)
    highlightContainer.parentNode.removeChild(highlightContainer)
    waterMarkEl.parentNode.removeChild(waterMarkEl)
    body = document.documentElement.outerHTML
    button.innerHTML = "Saving..."
    button.setAttribute("disabled", "disabled")
    document.body.appendChild(uiEl)
    document.body.appendChild(highlightContainer)
    document.body.appendChild(waterMarkEl)

    apiCall "PUT", "/files/#{file.path}", {
      body: body
      contentType: 'application/octet-stream'
    }, (err, xhr) ->
      if err
        button.innerHTML = "Error :("
      else
        file = JSON.parse(xhr.responseText)
        waitForReady file.site_id, file.deploy_id, ->
          button.innerHTML = "Save"


colorRegexp = (color) -> new RegExp(color.replace(/\(/, '\\(').replace(/\)/, '\\)'))

addSaveButton = ->
  uiEl = document.createElement("div")
  button = document.createElement("button")
  button.innerHTML = "Save"
  button.setAttribute("style", "padding: 10px 20px !important; background: rgb(57, 221, 127) !important; " +
                               "box-sizing: border-box !important; border: none !important; color: #fff !important; " +
                               "font-family: \"HelveticaNeue-Light\", \"Helvetica Neue Light\", \"Helvetica Neue\", Helvetica, Arial, \"Lucida Grande\", sans-seri !important;" +
                               "font-size: 16px !important; font-weight: bold !important; border-radius: 20px !important;  cursor: pointer !important")
  uiEl.appendChild(button)
  uiEl.setAttribute("style", "position: fixed; z-index: 2147483647; right: 10px; bottom: 37px;")

  document.body.appendChild(uiEl)
  uiEl.addEventListener "click", (e) ->
    e.preventDefault()
    saveChanges (err) ->
      if err then console.log(err) else console.log("Saved")
  , false
  button.addEventListener "mouseenter", (e) ->
    regepx = colorRegexp(buttonColor)
    button.setAttribute("style", button.getAttribute("style").replace(regepx, buttonHoverColor))
  , false
  button.addEventListener "mouseleave", (e) ->
    regepx = colorRegexp(buttonHoverColor)
    button.setAttribute("style", button.getAttribute("style").replace(regepx, buttonColor))
  , false


highlightElement = (element) ->
  return if welcomeOverlay
  rect = element.getBoundingClientRect()
  top  = window.scrollY + rect.top

  position(highlightElements.top, top, rect.left + 2, rect.width - 4, 0)
  position(highlightElements.rgt, top, rect.left + rect.width + 2, 0, rect.height)
  position(highlightElements.bottom, top + rect.height, rect.left + 2, rect.width - 4, 0)
  position(highlightElements.lft, top, rect.left - 2, 0, rect.height)
  highlightContainer.display = "block"

isUIElement = (element) ->
  while element
    return true if element == uiEl || element == highlightContainer || element == welcomeOverlay || element == waterMarkEl
    element = element.parentElement
  false

hoverHandler = (e) ->
  return if isUIElement(e.target)
  highlightElement(e.target)

editHandler = (e) ->
  e.preventDefault()

  return if welcomeOverlay

  #currentElement.removeAttribute("contentEditable") if currentElement
  #currentElement = e.target
  #contentBeforeEdit = currentElement.outerHTML
  #currentElement.contentEditable = true
  #currentElement.focus()
  #highlightElement.style.display = "none"
  return console.log("Current selector: " + uniqueSelector(e.target))

bindTextElements = ->
  elements = document.querySelectorAll("h1, h2, h3, h4, h5, h6, div, p, a, span, small, blockquote, label, cite, li")

  for element in elements
    continue if isUIElement(element)
    textNodes = (node for node in element.childNodes when node.nodeType == node.TEXT_NODE && node.textContent.replace(/\s/))
    continue unless textNodes.length

    element.addEventListener('mouseover', hoverHandler, false)
    element.addEventListener('click', editHandler, false)
    # element.addEventListener('blur', blurHandler, false)

bindImgElements = ->
  imgs = document.querySelectorAll("img")
  for img in imgs
    continue if isUIElement(img)
    do (img) ->

      container    = document.createElement("div")
      input        = document.createElement("input")
      input.type   = "file"
      input.accept = "image/*"
      input.style.opacity = "0"
      input.style.display = "block"
      input.style.width   = "100%"
      input.style.height  = "100%"

      container.style.opacity = "0"
      container.style.background = "#eee"
      container.style.zIndex = "999999"
      container.appendChild(input)
      document.body.appendChild(container)
      input.addEventListener "mouseover", (e) ->
        return if welcomeOverlay
        highlightElement(input)
        container.style.opacity = "0.5"
      , false

      input.addEventListener "mouseout", (e) ->
        container.style.opacity = "0"
      , false

      input.addEventListener "change", (e) ->
        imageUploaded(img, input)
      , false

      img.onload = -> coverElement(img, container)
      coverElement(img, container)

enterEditingMode = ->
  addSaveButton()
  addHighlightElements()
  bindImgElements()
  bindTextElements()
  # getFileListing()

enterEditingMode()
document.addEventListener("hashchange", enterEditingMode, false)