#!/bin/bash

# Claud'ed this, it's slow but it works lol
# BMFont to QML CharMap Converter
# Usage: ./bmfont_to_charmap.sh input.fnt [output.js]

input_file="$1"
output_file="${2:-charmap.js}"

if [ -z "$input_file" ]; then
    echo "Usage: $0 <input.fnt> [output.js]"
    echo "Example: $0 MusicTitleFont.fnt musicfont_charmap.js"
    exit 1
fi

if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found!"
    exit 1
fi

echo "Converting $input_file to QML charMap..."

# Start writing the JavaScript/QML object
cat > "$output_file" << 'EOF'
// Auto-generated character map from BMFont .fnt file
// Usage in QML:
// property var charMap: FontCharMap.charMap

.pragma library

var charMap = {
EOF

# Parse the .fnt file and extract character data
grep "^char id=" "$input_file" | while IFS= read -r line; do
    # Extract values using parameter expansion and pattern matching
    char_id=$(echo "$line" | sed -n 's/.*char id=\([0-9]*\).*/\1/p')
    x_pos=$(echo "$line" | sed -n 's/.*x=\([0-9]*\).*/\1/p')
    y_pos=$(echo "$line" | sed -n 's/.*y=\([0-9]*\).*/\1/p')
    width=$(echo "$line" | sed -n 's/.*width=\([0-9]*\).*/\1/p')
    height=$(echo "$line" | sed -n 's/.*height=\([0-9]*\).*/\1/p')
    xoffset=$(echo "$line" | sed -n 's/.*xoffset=\([-0-9]*\).*/\1/p')
    yoffset=$(echo "$line" | sed -n 's/.*yoffset=\([-0-9]*\).*/\1/p')
    xadvance=$(echo "$line" | sed -n 's/.*xadvance=\([0-9]*\).*/\1/p')

    # Convert character ID to character (if printable) for comments
    if [ "$char_id" -ge 32 ] && [ "$char_id" -le 126 ]; then
        char_comment="// '$(printf "\\$(printf %03o "$char_id")")'"
    elif [ "$char_id" -eq 32 ]; then
        char_comment="// ' ' (space)"
    else
        char_comment="// Unicode: $char_id"
    fi

    # Write the character data
    echo "    $char_id: {x: $x_pos, y: $y_pos, width: $width, height: $height, xoffset: $xoffset, yoffset: $yoffset, xadvance: $xadvance}, $char_comment" >> "$output_file"
done

# Close the JavaScript object
cat >> "$output_file" << 'EOF'
};

// Helper function to get character data safely
function getCharData(charCode) {
    return charMap[charCode] || charMap[32] || {x: 0, y: 0, width: 0, height: 0, xoffset: 0, yoffset: 0, xadvance: 5};
}

// Get font info (you may need to adjust these values based on your .fnt file)
var fontInfo = {
    lineHeight: 19,
    base: 15,
    size: 19
};
EOF

echo "Conversion complete! Output written to: $output_file"
echo ""
echo "To use in QML:"
echo "1. Import the file: import \"$output_file\" as FontCharMap"
echo "2. Use the charMap: property var charMap: FontCharMap.charMap"
echo "3. Access character data: FontCharMap.getCharData(charCode)"

# Also create a simple QML component example
example_file="${output_file%.*}_example.qml"
cat > "$example_file" << EOF
import QtQuick 2.15
import "$output_file" as FontCharMap

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
EOF

echo "Example QML component created: $example_file"
