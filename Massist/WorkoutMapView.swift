import SwiftUI
import MapKit
import CoreLocation

struct WorkoutMapView: View {

    @ObservedObject var tracker: WorkoutTracker

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {

        Map(position: $cameraPosition) {

            if !tracker.route.isEmpty {

                MapPolyline(
                    coordinates: tracker.route.map {
                        $0.coordinate
                    }
                )
                .stroke(
                    Color.primaryOrange,
                    lineWidth: 5
                )
            }

            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onAppear {

            cameraPosition = .userLocation(
                followsHeading: true,
                fallback: .automatic
            )
        }
    }
}