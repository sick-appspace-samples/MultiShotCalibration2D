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

-- Delay in ms between visualization steps for demonstration purpose
local DELAY = 1000

-- Creating viewer
local viewer = View.create()
viewer:setID('viewer2D')

-- Creating header text and decoration attributes
local text = View.TextDecoration.create()
text:setPosition(25, 25) -- In pixels before origin is set in world coordinate
text:setSize(55) -- In pixels before sizes are defined in mm
text:setColor(0, 230, 0)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function main()
  -- Creating and setting up a camera calibration for internal camera parameters
  local calibrator = Image.Calibration.Camera.create()
  calibrator:setTargetType('CHECKERBOARD') -- Selecting the type of checkerboard
  calibrator:setCheckerSquareSideLength(15.09) -- Setting size of a square in world coordinates
  calibrator:setDistortionCoefficientsEnabled(true, true, false, false, false)

  -- Adding images to calibration object
  local numberOfImages = 10 -- At least 6 images, preferably 9 or more.
  for i = 0, numberOfImages - 1 do
    local image = Image.load('resources/camera/' .. i .. '.bmp')
    calibrator:addImage(image)
    viewer:add(image)
    viewer:add(string.format('%.0f', i), text) -- Print i without decimals
    viewer:present()
  end

  -- Calibrate intrinsic camera parameters
  local _, cameraModel, _, error = calibrator:calculate()
  print('Camera calibrated with average error: ' .. math.floor(error * 100) / 100 .. ' px')

  -- Update camera model with camera pose
  local squareSize = 166.0 / 11 -- mm
  local poseImage = Image.load('resources/pose/pose.bmp')
  viewer:add(poseImage)
  viewer:add('Pose calibration', text)
  viewer:present()
  Script.sleep(DELAY) -- For demonstration purpose only

  local cameraModelPose,
    errorPose = Image.Calibration.Pose.estimateCoordinateCode(cameraModel, poseImage, {squareSize})
  print('Pose calibrated with average error: ' .. math.floor(errorPose * 100) / 100 .. ' px')

  -- Showing the different correction modes
  local correction = Image.Calibration.Correction.create()

  -- Undistort mode removes lens distortion effects, but keeps perspective
  correction:setUndistortMode(cameraModelPose, 'VALID')
  local correctedImage = correction:apply(poseImage)
  viewer:add(correctedImage)
  viewer:add('Undistort mode', text)
  viewer:present()
  Script.sleep(DELAY) -- For demonstration purpose only

  -- Changing text position and size to mm and world coordinates
  text:setPosition(0, 0)
  text:setSize(12)

  -- Untilt mode compensates perspective and lens distortion effects
  correction:setUntiltMode(cameraModelPose, 'FULL')
  correctedImage = correction:apply(poseImage)
  viewer:add(correctedImage)
  viewer:add('Untilt mode', text)
  viewer:present()
  Script.sleep(DELAY) -- For demonstration purpose only

  ---- Align mode removes perspective and lens distortion effects and aligns to a world rectangle
  local cxy = squareSize * 6 -- Selected center point for aligned image in both x and y
  local sxy = squareSize * 13 -- Select the size of the alignment region in both x and y
  local worldRectangle = Shape.createRectangle(Point.create(cxy, cxy), sxy, sxy)
  correction:setAlignMode(cameraModelPose, worldRectangle)
  correctedImage = correction:apply(poseImage)
  viewer:add(correctedImage)
  viewer:add('Align mode', text)
  viewer:present()
  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
