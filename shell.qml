import Quickshell
import QtQuick
import Quickshell.Io

import "./fonts/MusicTitleFont.js" as MusicTitleFont
import "./fonts/ShinonomeGothic.js" as ShinonomeGothic
import "./fonts/Ramche.js" as Ramche

PanelWindow {
    anchors {
        top: true
        right: true
    }

    color: "transparent"

    property real margin: 40
    implicitWidth: child.implicitWidth + margin * 2 + bitmapTitle.textWidth
    implicitHeight: child.implicitHeight + margin * 2

    property string musicTitleFontImage: "./fonts/MusicTitleFont.png"
    property string shinonomeGothicImage: "./fonts/ShinonomeGothic.png"
    property string ramcheImage: "./fonts/Ramche.png"

    Item {
        id: child
        anchors.right: parent.right
        anchors.rightMargin: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        Item {
            id: bitmapTitle

            property string text: ""
            property real textWidth: 50
            property real characterSpacing: 1.2
            property string fontImage: "./fonts/MusicTitleFont.png"

            width: textRow.width
            height: MusicTitleFont.fontInfo.lineHeight

            function getFontForChar(charCode) {
                if (charCode === 32) {
                    return {
                        charMap: {},
                        getCharData: function (code) {
                            return {
                                x: 0,
                                y: 0,
                                width: 3.5,
                                height: 19,
                                xoffset: 0,
                                yoffset: 0,
                                xadvance: 10
                            };
                        },
                        fontImage: "" // no image for space
                    };
                } else
                // Musical note and basic ASCII (English) - use MusicTitleFont
                if (charCode === 9834 || (charCode >= 33 && charCode <= 126)) {
                    return {
                        charMap: MusicTitleFont.charMap,
                        getCharData: MusicTitleFont.getCharData,
                        fontImage: musicTitleFontImage
                    };
                } else
                // Hiragana, Katakana, Kanji ranges (Japanese) - use ShinonomeGothic
                if ((charCode >= 0x3040 && charCode <= 0x309F) ||  // Hiragana
                (charCode >= 0x30A0 && charCode <= 0x30FF) ||  // Katakana
                (charCode >= 0x4E00 && charCode <= 0x9FAF)) {
                    // CJK Unified Ideographs
                    return {
                        charMap: ShinonomeGothic.charMap,
                        getCharData: function (code) {
                            var data = ShinonomeGothic.getCharData(code);
                            // Push Japanese characters down by 5 pixels (will be scaled 2x to 10px)
                            return {
                                x: data.x,
                                y: data.y,
                                width: data.width,
                                height: data.height,
                                xoffset: data.xoffset,
                                yoffset: data.yoffset + 5,
                                xadvance: data.xadvance
                            };
                        },
                        fontImage: shinonomeGothicImage
                    };
                } else
                // Hangul ranges (Korean) - use Ramche
                if ((charCode >= 0xAC00 && charCode <= 0xD7AF) ||  // Hangul Syllables
                (charCode >= 0x1100 && charCode <= 0x11FF) ||  // Hangul Jamo
                (charCode >= 0x3130 && charCode <= 0x318F)) {
                    // Hangul Compatibility Jamo
                    return {
                        charMap: Ramche.charMap,
                        getCharData: function (code) {
                            var data = Ramche.getCharData(code);
                            // Push Korean characters down by 5 pixels (will be scaled 2x to 10px)
                            return {
                                x: data.x,
                                y: data.y,
                                width: data.width,
                                height: data.height,
                                xoffset: data.xoffset,
                                yoffset: data.yoffset + 5,
                                xadvance: data.xadvance
                            };
                        },
                        fontImage: ramcheImage
                    };
                } else
                // Default fallback to MusicTitleFont
                {
                    return {
                        charMap: MusicTitleFont.charMap,
                        getCharData: MusicTitleFont.getCharData,
                        fontImage: musicTitleFontImage
                    };
                }
            }

            Row {
                id: textRow
                spacing: bitmapTitle.characterSpacing

                Repeater {
                    model: bitmapTitle.text.length

                    Image {
                        property int charCode: bitmapTitle.text.charCodeAt(index)
                        property var fontData: bitmapTitle.getFontForChar(charCode)
                        property var charData: fontData.getCharData(charCode)

                        source: fontData.fontImage
                        sourceClipRect: Qt.rect(charData.x, charData.y, charData.width, charData.height)

                        width: charData.width * 2
                        height: charData.height * 2
                        x: charData.xoffset // * 2
                        y: charData.yoffset // * 2

                        smooth: false
                    }
                }
            }

            // Process to get the current playing song title
            Process {
                command: ["playerctl", "metadata", "xesam:title"]
                running: true

                stdout: StdioCollector {
                    onStreamFinished: {
                        var title = this.text.trim().toUpperCase();
                        if (title.length > 0) {
                            bitmapTitle.text = "♪ ~ " + title;
                            bitmapTitle.textWidth = (bitmapTitle.text.length * 14) + 50;
                        } else {
                            bitmapTitle.text = "";
                        }
                    }
                }
            }

            // Timer to refresh the title periodically
            Timer {
                interval: 2000
                running: true
                repeat: true
                onTriggered: {
                    var proc = Qt.createQmlObject(`
                        import Quickshell.Io
                        Process {
                        command: ["playerctl", "metadata", "xesam:title"]
                        running: true
                        stdout: StdioCollector {
                            onStreamFinished: {
                            var title = this.text.trim().toUpperCase()
                            if (title.length > 0) {
                                bitmapTitle.text =  "♪ ~ " + title;
                                bitmapTitle.textWidth = (bitmapTitle.text.length * 14) + 50;
                            } else {
                                bitmapTitle.text = "NO MUSIC PLAYING"
                            }
                            // parent.destroy()
                            }
                        }
                        }
                    `, bitmapTitle);
                }
            }
        }
    }
}
