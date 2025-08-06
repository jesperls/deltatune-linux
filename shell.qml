import Quickshell
import QtQuick
import Quickshell.Io

import "./fonts/MusicTitleFont.js" as MusicTitleFont
import "./fonts/ShinonomeGothic.js" as ShinonomeGothic
import "./fonts/Ramche.js" as Ramche

PanelWindow {
    id: deltatune

    anchors {
        top: true
        right: true
    }

    margins {
        top: 25
        right: 25
    }

    color: "transparent"

    implicitWidth: bitmapTitle.width * 2
    implicitHeight: bitmapTitle.height * 2

    property string musicTitleFontImage: "./fonts/MusicTitleFont.png"
    property string shinonomeGothicImage: "./fonts/ShinonomeGothic.png"
    property string ramcheImage: "./fonts/Ramche.png"

    Item {
        id: child
        width: deltatune.implicitWidth
        height: deltatune.implicitHeight

        Item {
            id: bitmapTitle

            property string text: ""
            property real characterSpacing: 1.2
            property string fontImage: "./fonts/MusicTitleFont.png"
            property string currentTitle: ""
            property string currentStatus: ""
            property bool isAnimating: false
            property real slideOffset: 30
            property real baseX: deltatune.implicitWidth - width

            width: textRow.width
            height: MusicTitleFont.fontInfo.lineHeight

            opacity: 0.0
            x: baseX - slideOffset

            Behavior on opacity {
                enabled: !bitmapTitle.isAnimating
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.InOutQuad
                    onRunningChanged: {
                        if (!running && bitmapTitle.opacity === 0.0) {
                            bitmapTitle.x = bitmapTitle.baseX - bitmapTitle.slideOffset;
                        }
                    }
                }
            }

            Behavior on x {
                enabled: !bitmapTitle.isAnimating
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
            }

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
                        x: charData.xoffset * 2
                        y: charData.yoffset // * 2

                        smooth: false
                    }
                }
            }

            function updateMusicInfo() {
                var statusProc = Qt.createQmlObject(`
                    import Quickshell.Io
                    Process {
                        command: ["playerctl", "status"]
                        running: true
                        stdout: StdioCollector {
                            onStreamFinished: {
                                bitmapTitle.currentStatus = this.text.trim();
                                bitmapTitle.checkTitleUpdate();
                            }
                        }
                    }
                `, bitmapTitle);
            }

            function checkTitleUpdate() {
                if (currentStatus === "Playing") {
                    var titleProc = Qt.createQmlObject(`
                        import Quickshell.Io
                        Process {
                            command: ["playerctl", "metadata", "xesam:title"]
                            running: true
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    var newTitle = this.text.trim();
                                    if (newTitle.length > 0 && newTitle !== bitmapTitle.currentTitle) {
                                        bitmapTitle.currentTitle = newTitle;
                                        bitmapTitle.text = "♪ ~ " + newTitle;
                                        bitmapTitle.showTitle();
                                    } else if (newTitle.length === 0) {
                                        bitmapTitle.hideTitle();
                                    }
                                }
                            }
                        }
                    `, bitmapTitle);
                } else {
                    hideTitle();
                }
            }

            function showTitle() {
                hideTimer.stop();
                isAnimating = true;
                opacity = 0.0;
                x = baseX - slideOffset;
                showAnimationTimer.start();
            }

            Timer {
                id: showAnimationTimer
                interval: 10
                repeat: false
                onTriggered: {
                    bitmapTitle.isAnimating = false;
                    bitmapTitle.opacity = 1.0;
                    bitmapTitle.x = bitmapTitle.baseX;
                    hideTimer.restart();
                }
            }

            function hideTitle() {
                hideTimer.stop();
                showAnimationTimer.stop();
                isAnimating = false;
                opacity = 0.0;
                x = baseX - slideOffset;
            }

            Timer {
                id: hideTimer
                interval: 7000
                running: false
                repeat: false
                onTriggered: bitmapTitle.hideTitle()
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: bitmapTitle.updateMusicInfo()
            }

            Component.onCompleted: updateMusicInfo()
        }
    }
}
