.pragma library

var c = {
  // Position
  // Default is top & right true to put it in the top-right of the screen
  // To center it on an axis, set both relevant anchors to true
  anchors: {
    top: true,
    right: true,
    bottom: false,
    left: false,
  },

  // Slide offset
  // The horizontal distance in pixels the title slides in/out
  // Set this to a negative number if you're anchoring to the left
  slideOffset: 30,

  // Margins
  margins: {
    top: 25,
    right: 25,
    bottom: 0,
    left: 0,
  },

  // How long to show the title for (in milliseconds)
  titleDuration: 7000,

  // Animation duration (in milliseconds)
  animationDuration: 600,

  // Scale
  // Highly recommended to just keep this as 2
  // Whole numbers only!
  scale: 2,

  // Background color
  // Highly recommended to just keep this as "transparent"
  backgroundColor: "transparent"
}
