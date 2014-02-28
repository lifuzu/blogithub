`var sha1;(function(h){var f=Math.pow(2,24);var c=Math.pow(2,32);function d(m){var l="",j;for(var k=7;k>=0;--k){j=(m>>>(k<<2))&15;l+=j.toString(16)}return l}function e(j,i){return((j<<i)|(j>>>(32-i)))}var b=(function(){function i(j){this.bytes=new Uint8Array(j<<2)}i.prototype.get=function(j){j<<=2;return(this.bytes[j]*f)+((this.bytes[j+1]<<16)|(this.bytes[j+2]<<8)|this.bytes[j+3])};i.prototype.set=function(j,m){var l=Math.floor(m/f),k=m-(l*f);j<<=2;this.bytes[j]=l;this.bytes[j+1]=k>>16;this.bytes[j+2]=(k>>8)&255;this.bytes[j+3]=k&255};return i})();function a(k){k=k.replace(/[\u0080-\u07ff]/g,function(n){var i=n.charCodeAt(0);return String.fromCharCode(192|i>>6,128|i&63)});k=k.replace(/[\u0080-\uffff]/g,function(n){var i=n.charCodeAt(0);return String.fromCharCode(224|i>>12,128|i>>6&63,128|i&63)});var m=k.length,l=new Uint8Array(m);for(var j=0;j<m;++j){l[j]=k.charCodeAt(j)}return l.buffer}function g(F){var v;if(F instanceof ArrayBuffer){v=F}else{v=a(String(F))}var q=1732584193,p=4023233417,o=2562383102,n=271733878,m=3285377520,C,A=v.byteLength,x=A<<3,K=x+65,z=Math.ceil(K/512)<<9,u=z>>>3,L=u>>>2,t=new b(L),N=t.bytes,B,r=new Uint32Array(80),l=new Uint8Array(v);for(C=0;C<A;++C){N[C]=l[C]}N[A]=128;t.set(L-2,Math.floor(x/c));t.set(L-1,x&4294967295);for(C=0;C<L;C+=16){for(B=0;B<16;++B){r[B]=t.get(C+B)}for(;B<80;++B){r[B]=e(r[B-3]^r[B-8]^r[B-14]^r[B-16],1)}var M=q,J=p,I=o,H=n,E=m,D,y,G;for(B=0;B<80;++B){if(B<20){D=(J&I)|((~J)&H);y=1518500249}else{if(B<40){D=J^I^H;y=1859775393}else{if(B<60){D=(J&I)^(J&H)^(I&H);y=2400959708}else{D=J^I^H;y=3395469782}}}G=(e(M,5)+D+E+y+r[B])&4294967295;E=H;H=I;I=e(J,30);J=M;M=G}q=(q+M)&4294967295;p=(p+J)&4294967295;o=(o+I)&4294967295;n=(n+H)&4294967295;m=(m+E)&4294967295}return d(q)+d(p)+d(o)+d(n)+d(m)}h.hash=g})(sha1||(sha1={}));`

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

apiCall = (method, url, options, cb) ->
  cb = options unless cb

  xhr = new XMLHttpRequest()

  xhr.onload = -> cb(null, xhr)
  xhr.onerror = -> cb(xhr, null)

  url = if options.fullPath then "#{resourceHost}#{url}"  else "#{resourceHost}/sites/#{document.location.host}#{url}"

  xhr.open(method, url, true)
  xhr.setRequestHeader('Authorization', "Bearer " + token)
  if open.contentType
    xhr.setRequestHeader('Content-Type', )
  if options.body then xhr.send(options.body) else xhr.send()

ajax = (method, path, options, cb) ->
  cb = options unless cb

  options.retries = 3

  xhr = new XMLHttpRequest

  xhr.onload = -> cb(null, xhr)
  xhr.onerror = ->
    if options.retries > 0 && (method == "PUT" || method == "GET") && xhr.status != 422
      options.retries -= 1
      ajax(method, path, options, cb)
    else
      console.log("Error fetching file %o", xhr)
      cb(xhr)

  xhr.open(method, path, true)

  xhr.responseType = "blob" if options.blob

  for own header, value of options.headers || {}
    xhr.setRequestHeader(header, value)

  if options.body then xhr.send(options.body) else xhr.send()

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
  currentElement = e.target
  contentBeforeEdit = currentElement.outerHTML
  #currentElement.contentEditable = true
  #currentElement.focus()
  #highlightElement.style.display = "none"
  console.log("Content: " + contentBeforeEdit)
  return console.log("Current selector: " + uniqueSelector(e.target))

saveHandler = (e) ->
  e.preventDefault()
  # Get the content of the current selected element
  contentHtml = e.target.outerHTML
  # Transform to md, and imgs (if have)
  contentMd = md(contentHtml)
  console.log(contentMd)
  # upload the md, and images to server, with a manifest, sha1 accompanied
  files = []
  files.push({path: 'index.md', content: contentMd})
  upload(files)

upload = (files) ->
  articleHost = "http://localhost:3000"
  # Create a manifest of all the file paths and their sha1 digests
  manifest = {}
  for file in files
    manifest[file.path] = sha1.hash(file.content).toString()

  ajax "POST", "#{articleHost}/article", {
    headers: {"Content-Type": "application/json"}
    body: JSON.stringify({
      files: manifest
    })
  }, (err, xhr) ->
    return alert("Failed to apply article ID when uploading") if err

    # Get the article ID at response text: article.id
    article = JSON.parse(xhr.responseText)

    for file in files
      do (file) ->
        ajax "PUT", "#{articleHost}/article/#{article.id}/#{file.path}", {
          headers: {"Content-Type": "application/octet-stream"}
          body: file.content
        }, (err, xhr) ->
          return console.log("Failed to upload file: " + file.path) if err
    console.log("Uploading done!")

bindElement = ->
  # Bind the current active element when hover

bindTextElements = ->
  elements = document.querySelectorAll("h1, h2, h3, h4, h5, h6, div, p, a, span, small, blockquote, label, cite, li")

  for element in elements
    continue if isUIElement(element)
    textNodes = (node for node in element.childNodes when node.nodeType == node.TEXT_NODE && node.textContent.replace(/\s/))
    continue unless textNodes.length

    element.addEventListener('mouseover', hoverHandler, false)
    element.addEventListener('click', saveHandler, false)
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