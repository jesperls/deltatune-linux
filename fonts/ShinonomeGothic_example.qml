import QtQuick 2.15
import "./fonts/ShinonomeGothic.js" as FontCharMap

// Example BitmapText component using the generated charMap
Item {
    id: bitmapText
    
    property string text: "HELLO WORLD"
    property int characterSpacing: 0
    property string fontImage: "MusicTitleFont.png"  // Update this path
    
    width: textRow.width
    height: FontCharMap.fontInfo.lineHeight
    
    Row {
        id: textRow
        spacing: characterSpacing
        
        Repeater {
            model: bitmapText.text.length
            
            Image {
                source: bitmapText.fontImage
                
                property int charCode: bitmapText.text.charCodeAt(index)
                property var charData: FontCharMap.getCharData(charCode)
                
                sourceClipRect: Qt.rect(charData.x, charData.y, charData.width, charData.height)
                width: charData.width
                height: charData.height
                x: charData.xoffset
                y: charData.yoffset
            }
        }
    }
}
