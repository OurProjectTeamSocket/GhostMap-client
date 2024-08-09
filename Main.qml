import QtQuick
import QtLocation 6.7
import QtPositioning 6.7

Window {
    id: window
    width: 640
    height: 480
    visible: true
    title: qsTr("Hello World")

    Rectangle {
        id: top

        width: window.width
        height: window.height/8

        color: "black"

        Rectangle {
            id: searchbar

            width: top.width/1.2
            height: top.height/2

            color: "white"

            x: top.width/2 - searchbar.width/2
            y: top.height/2 - searchbar.height/2

            radius: 10
        }

    }

    Rectangle {
        id: bottom

        width: window.width
        height: window.height/8

        color: "black"

        y: window.height - bottom.height

        Row {

            anchors{
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            height: parent.height
            width: childrenRect.width
            spacing: 60

            Rectangle {
                id: one

                width: bottom.width/8
                height: bottom.height/2

                color: "white"

                // x: bottom.width/3
                y: bottom.height/2 - height/2

                radius: 10
            }

            Rectangle {
                id: two

                width: bottom.width/8
                height: bottom.height/2

                color: "white"

                // x: bottom.width/2
                y: bottom.height/2 - height/2

                radius: 10
            }

            Rectangle {
                id: three

                width: bottom.width/8
                height: bottom.height/2

                color: "white"

                // x: bottom.width
                y: bottom.height/2 - height/2

                radius: 10
            }
        }

    }

    PositionSource {
        id: positionSource
        updateInterval: 1000
        active: true
        preferredPositioningMethods: PositionSource.AllPositioningMethods

        onPositionChanged: {
            var position = positionSource.position.coordinate
            console.log("Latitude: " + position.latitude + "\nLongitude: " + position.longitude)
        }
    }

    Plugin {
        id: mapPlugin
        name: "osm"
    }

    Rectangle {
        id: mapBox

        height: window.height - ( top.height + bottom.height )
        width: window.width

        y: top.height

        Map {
            id: map
            anchors.fill: parent
            plugin: mapPlugin
            center: QtPositioning.coordinate(positionSource.position.coordinate.latitude, positionSource.position.coordinate.longitude)
            // center: QtPositioning.coordinate(0, 0)
            zoomLevel: 14
            property geoCoordinate startCentroid

            MapCircle {
                center {
                    latitude: positionSource.position.coordinate.latitude
                    longitude: positionSource.position.coordinate.longitude
                }
                radius: 3.0
                color: 'purple'
                border.width: 3
                opacity: 0.8
            }

            PinchHandler {
                id: pinch
                target: null
                onActiveChanged: if (active) {
                    map.startCentroid = map.toCoordinate(pinch.centroid.position, false)
                }
                onScaleChanged: (delta) => {
                    map.zoomLevel += Math.log2(delta)
                    map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
                }
                onRotationChanged: (delta) => {
                    map.bearing -= delta
                    map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
                }
                grabPermissions: PointerHandler.TakeOverForbidden
            }
            WheelHandler {
                id: wheel
                // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
                // Magic Mouse pretends to be a trackpad but doesn't work with PinchHandler
                // and we don't yet distinguish mice and trackpads on Wayland either
                acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                                 ? PointerDevice.Mouse | PointerDevice.TouchPad
                                 : PointerDevice.Mouse
                rotationScale: 1/120
                property: "zoomLevel"
            }
            DragHandler {
                id: drag
                target: null
                onTranslationChanged: (delta) => map.pan(-delta.x, -delta.y)
            }
            Shortcut {
                enabled: map.zoomLevel < map.maximumZoomLevel
                sequence: StandardKey.ZoomIn
                onActivated: map.zoomLevel = Math.round(map.zoomLevel + 1)
            }
            Shortcut {
                enabled: map.zoomLevel > map.minimumZoomLevel
                sequence: StandardKey.ZoomOut
                onActivated: map.zoomLevel = Math.round(map.zoomLevel - 1)
            }
        }
    }
}
