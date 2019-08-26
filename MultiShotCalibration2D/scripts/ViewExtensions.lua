local function getHistogram(vector, count, lower, upper)
  local binsize = (upper - lower) / count
  local hist = {}
  for i = 1, count do hist[i] = 0 end
  for i = 1, #vector do
    local bin = math.floor((vector[i] - lower) / binsize) + 1
    if bin < 1 then hist[1] = hist[1] + 1
    elseif bin > count then hist[count] = hist[count] + 1
    else hist[bin] = hist[bin] + 1 end
  end
  return hist
end

local function getPolyline(vector, stepx, height, steps)
  local poly = {}

  local scale = height / steps
  for i = 1, #vector do
    poly[#poly+1] = Point.create(math.min(height, vector[i]*scale), stepx*(i-1))
  end
  return Shape.createPolyline(poly, false)
end

local function addAreaFeedback(self, parent, score)
  local imw, imh = score:getSize()
  local w, h = score:getPixelSize()

  for r = 0, imh - 1 do
    for c = 0, imw - 1 do
      local color = score:getPixel(c, r)
      local shape = Shape.createRectangle(Point.create(w*c + w/2, h*r + h/2), w, h)
      local deco = View.ShapeDecoration.create()

      local green = math.min(255, 25.5 * color)
      local red = 255 - green
      deco:setFillColor(red, green, 0, 120)
      deco:setLineColor(255, 255, 255, 120)
      deco:setLineWidth(1)
      self:addShape(shape, deco, nil, parent)
    end
  end
end

local function addDistanceFeedback(self, parent, distance, xpos, height, pad)
  local maxDistance, minDistance
  if #distance > 1 then
    maxDistance = distance[1]
    minDistance = distance[1]
    for i = 2, #distance do
      if maxDistance < distance[i] then maxDistance = distance[i] end
      if minDistance > distance[i] then minDistance = distance[i] end
    end
  else
    minDistance = distance[1]
    maxDistance = distance[1]
  end

  minDistance = minDistance / 1.2
  maxDistance = maxDistance * 1.2

  -- Draw a ruler
  local rulerDeco = View.ShapeDecoration.create()
  rulerDeco:setLineColor(255, 255, 255, 120)
  rulerDeco:setLineWidth(1)
  self:addShape(Shape.createLineSegment(Point.create(xpos, 0), Point.create(xpos, height)), rulerDeco, nil, parent)
  local step_count = math.max(1, math.ceil((maxDistance - minDistance) * height / 200))
  local step = height / step_count
  for i = 0, step_count do
    local ypos = step * i
    self:addShape(Shape.createLineSegment(Point.create(xpos + pad, ypos), Point.create(xpos, ypos)), rulerDeco, nil, parent)
  end

  -- Draw observations along the ruler
  local bincount = 7
  local hist = getHistogram(distance, bincount, minDistance, maxDistance)
  local poly = getPolyline(hist, height / (bincount - 1), pad, 1)
  poly = poly:transform(Transform.createTranslation2D(xpos, 0))
  local deco = View.ShapeDecoration.create()
  deco:setLineColor(255, 255, 255, 180)
  deco:setLineWidth(height / 200)
  self:addShape(poly, deco, nil, parent)

  -- Put labels on the ruler
  local fontScale = height / 60
  local labeldeco = View.TextDecoration.create()
  labeldeco:setSize(2 * fontScale)
  labeldeco:setColor(255, 255, 255, 180)
  labeldeco:setPosition(xpos + fontScale, fontScale)
  self:addText(tostring(math.floor(minDistance)), labeldeco, nil, parent)
  labeldeco:setPosition(xpos + fontScale, height - fontScale * 2)
  self:addText(tostring(math.ceil(maxDistance)), labeldeco, nil, parent)
end

local function addTiltXFeedback(self, parent, tilt, width, height)
  local bincount = 7
  local hist = getHistogram(tilt, bincount, -1, 1)
  local poly = getPolyline(hist, width / (bincount - 1), height / 8, 2)

  local T = Transform.createFromMatrix2D(Matrix.createFromVector(
    {
      0, 1, 0,
      1, 0, 0, 
      0, 0, 1
    }, 3, 3))
  poly = Shape.transform(poly, T)

  local deco = View.ShapeDecoration.create()
  deco:setLineColor(255, 153, 51)
  deco:setLineWidth(height / 150)
  self:addShape(poly, deco, nil, parent)
end

local function addTiltYFeedback(self, parent, tilt, width, height)
  local bincount = 7
  local hist = getHistogram(tilt, bincount, -1, 1)
  local poly = getPolyline(hist, height / (bincount - 1), width / 8, 2)

  local deco = View.ShapeDecoration.create()
  deco:setLineColor(0, 136, 194)
  deco:setLineWidth(height / 150)
  self:addShape(poly, deco, nil, parent)
end

_G['View']['addAreaFeedback'] = addAreaFeedback
_G['View']['addDistanceFeedback'] = addDistanceFeedback
_G['View']['addTiltXFeedback'] = addTiltXFeedback
_G['View']['addTiltYFeedback'] = addTiltYFeedback