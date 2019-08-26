--[[----------------------------------------------------------------------------

  Application Name:
  MultiShotCalibration2D
      
  Summary:
  Camera calibration using multiple shots of checkerboard target covering different
  angles and various correction modes
                                                                                             
  Description:
  Calibrating a camera using multiple shots of a checkerboard calibration target,
  covering the field-of-view at different poses. Correcting the image by rectification
  using different correction modes.
  
  How to Run:
  Starting this sample is possible either by running the app (F5) or
  debugging (F7+F10). Setting breakpoint on the first row inside the 'main'
  function allows debugging step-by-step after 'Engine.OnStarted' event.
  Results can be seen in the image viewer on the DevicePage.
  To run this sample a device with SICK Algorithm API is necessary.
  For example InspectorP or SIM4000 with latest firmware. Alternatively the
  Emulator on AppStudio 2.2 or higher can be used. The images can be seen in the
  image viewer on the DevicePage.
     
  More Information:
  Tutorial "Algorithms - Calibration2D".

------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------

-- Point to folder containing calibration images
local resourcefolder = 'resources/'
local cameraImages = 'camera/'
local poseImageFile = 'pose/pose.bmp'

-- Used to list and get images from disk
local ImageLoader = require('ImageLoader')

-- Additions to the View crown for plotting feedback data
require('ViewExtensions')

-- Delay in ms between visualization steps for demonstration purpose
local DELAY = 1000

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------
local function main()
  local viewer = View.create()

  local countDeco = View.TextDecoration.create()
  countDeco:setColor(255, 255, 255)

  local text = View.TextDecoration.create()
  text:setPosition(25, 50) -- In pixels before origin is set in world coordinate
  text:setSize(55)         -- In pixels before sizes are defined in mm
  text:setColor(0, 230, 0)

  ------------------------------------------------------------------------
  -- Calibrated the intrinsics of the camera
  ------------------------------------------------------------------------
  local cal = Image.Calibration.Camera.create()
  cal:setCheckerSquareSideLength(15.09)
  cal:setDistortionCoefficientsEnabled(true, true, false, false, false)
  cal:setTargetType('CHECKERBOARD')

  -- Automatically discard images that are too similar to others
  cal:setUniquenessThreshold(true, 1.0)

  -- Initialize a function to get all images in the selected folder
  print("Image files in selected folder: " .. #ImageLoader.getFiles(resourcefolder .. cameraImages))
  local getImage = ImageLoader.getLoader(resourcefolder .. cameraImages)

  -- Run for each image in folder
  local image = getImage()
  while image do
    local tic = DateTime.getTimestamp()
    local ok, p2d, _, added = cal:addImage(image)

    if ok then
      -- Retrieve data for providing feedback
      local width, height = image:getSize()
      local area, tiltX, tiltY, distance, coverage = cal:getDataCompleteness()
      local boxWidth, _ = coverage:getPixelSize()

      local pdeco = View.ShapeDecoration.create()
      if not added then
        pdeco:setLineColor(255, 0, 0)
      else
        pdeco:setLineColor(0, 255, 0)
      end
      pdeco:setPointSize(height / 70)
      countDeco:setSize(height / 40)
      countDeco:setPosition(10, height - 10)

      -- Plot data
      viewer:clear()
      local imid = viewer:addImage(image)
      viewer:addShape(p2d, pdeco, nil, imid)
      viewer:addAreaFeedback(imid, coverage)
      viewer:addTiltXFeedback(imid, tiltX, width, height)
      viewer:addTiltYFeedback(imid, tiltY, width, height)
      viewer:addDistanceFeedback(imid, distance, width, height, boxWidth / 2)
      viewer:addText('Added: ' .. tostring(#area), countDeco, nil, imid)
      viewer:present()
    end

    -- Attempt to get another image
    image = getImage()

    -- Only wait the remainder of the delay time
    local timeConsumed = DateTime.getTimestamp() - tic
    Script.sleep(math.max(0, DELAY - timeConsumed))
  end

  -- Perform intrinsic calibration
  local model, avgerror = cal:estimate()
  print('Estimated model: ' .. model:toString())
  print('Average error: ' .. tostring(avgerror) .. ' px')

  ------------------------------------------------------------------------
  -- Update camera model with camera pose
  ------------------------------------------------------------------------
  local poseImage = Image.load(resourcefolder .. poseImageFile)
  local squareSize = 15.09
  viewer:clear()
  local imid = viewer:addImage(poseImage)
  viewer:addText('Pose calibration', text, nil, imid)
  viewer:present()
  Script.sleep(DELAY) -- For demonstration purpose only

  -- Run the estimation
  local modelWithPose, errorPose = Image.Calibration.Pose.estimateCoordinateCode(model, poseImage, {15.09})
  print("Pose calibrated with average error: " .. math.floor(errorPose*100)/100 .. " px")

  ------------------------------------------------------------------------
  -- Showing the different correction modes
  ------------------------------------------------------------------------
  local correction = Image.Calibration.Correction.create()

  -- Undistort mode removes lens distortion effects, but keeps perspective
  correction:setUndistortMode(modelWithPose, 'VALID')
  local correctedImage = correction:apply(poseImage)
  viewer:clear()
  imid = viewer:addImage(correctedImage)
  viewer:addText('Undistort mode', text, nil, imid)
  viewer:present()
  Script.sleep(DELAY) -- For demonstration purpose only

  -- Changing text position and size to mm and world coordinates
  text:setPosition(0, squareSize)
  text:setSize(12)

  -- Untilt mode compensates perspective and lens distortion effects
  correction:setUntiltMode(modelWithPose, 'FULL')
  correctedImage = correction:apply(poseImage)
  viewer:clear()
  imid = viewer:addImage(correctedImage)
  viewer:addText('Untilt mode', text, nil, imid)
  viewer:present()
  Script.sleep(DELAY) -- For demonstration purpose only

  ---- Align mode removes perspective and lens distortion effects and aligns to a world rectangle
  local cxy = squareSize * 6 -- Selected center point for aligned image in both x and y
  local sxy = squareSize * 13 -- Select the size of the alignment region in both x and y
  local worldRectangle = Shape.createRectangle(Point.create(cxy, cxy), sxy, sxy)
  correction:setAlignMode(modelWithPose, worldRectangle)
  correctedImage = correction:apply(poseImage)
  viewer:clear()
  imid = viewer:addImage(correctedImage)
  viewer:addText('Align mode', text, nil, imid)
  viewer:present()
  print('App finished.')
end

Script.register('Engine.OnStarted', main)
