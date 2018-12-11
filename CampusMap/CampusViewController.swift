//
//  CampusViewController.swift
//  CampusMap
//
//  Created by Chun on 2018/11/26.
//  Copyright © 2018 Nemoworks. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class CampusViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var campus = Campus(filename: "Campus")
    var selectedOptions : [MapOptionsType] = []
   
    let locationManager = CLLocationManager()
    var lnt:Double = 0
    var lat:Double = 0
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied:
            
            let alertController = UIAlertController(title: "Locating Denied", message: "You did not grant the locating permission for this app.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            return
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                //let pm = placemarks![0]
                if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
                    var currentLocation = self.locationManager.location
                    var longitude = currentLocation!.coordinate.longitude
                    var latitude = currentLocation!.coordinate.latitude
                    self.lnt = longitude
                    self.lat = latitude
                    print(longitude, latitude)
                }
                //self.displayLocationInfo(pm)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let latDelta = campus.overlayTopLeftCoordinate.latitude - campus.overlayBottomRightCoordinate.latitude
        
        // Think of a span as a tv size, measure from one corner to another
        let span = MKCoordinateSpan.init(latitudeDelta: fabs(latDelta), longitudeDelta: 0.0)
        let region = MKCoordinateRegion.init(center: campus.midCoordinate, span: span)
        
        mapView.region = region
        if ( CLLocationManager.authorizationStatus() == .notDetermined){
            locationManager.requestWhenInUseAuthorization()
            //locationManager.requestAlwaysAuthorization()
        }
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (segue.destination as? MapOptionsViewController)?.selectedOptions = selectedOptions
    }
    
    
    // MARK: Helper methods
    func loadSelectedOptions() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        for option in selectedOptions {
            switch (option) {
            case .mapPOIs:
                self.addPOIs()
            case .mapBoundary:
                self.addBoundary()
            }
        }
    }
    
    
    @IBAction func closeOptions(_ exitSegue: UIStoryboardSegue) {
        guard let vc = exitSegue.source as? MapOptionsViewController else { return }
        selectedOptions = vc.selectedOptions
        loadSelectedOptions()
    }
    
    
    //    func addOverlay() {
    //        let overlay = ParkMapOverlay(park: park)
    //        mapView.addOverlay(overlay)
    //    }
    //
    
    func addBoundary() {
        mapView.addOverlay(MKPolygon(coordinates: campus.boundary, count: campus.boundary.count))
    }
    
    func addPOIs() {
        guard let pois = Campus.plist("CampusPOI") as? [[String : String]] else { return }
        
        for poi in pois {
            let coordinate = Campus.parseCoord(dict: poi, fieldName: "location")
            let title = poi["name"] ?? ""
            let typeRawValue = Int(poi["type"] ?? "0") ?? 0
            let type = POIType(rawValue: typeRawValue) ?? .misc
            let subtitle = poi["subtitle"] ?? ""
            let annotation = POIAnnotation(coordinate: coordinate, title: title, subtitle: subtitle, type: type)
            mapView.addAnnotation(annotation)
        }
        
        let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(32.119572), CLLocationDegrees(118.958368))
        let title = "我的位置"
        let type:POIType = .misc
        let subtitle = "这里"
        let annotation = POIAnnotation(coordinate: coordinate, title: title, subtitle: subtitle, type: type)
        mapView.addAnnotation(annotation)
        
    }
    
    @IBAction func mapTypeChanged(_ sender: UISegmentedControl) {
        mapView.mapType = MKMapType.init(rawValue: UInt(sender.selectedSegmentIndex)) ?? .standard
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}


// MARK: - MKMapViewDelegate
extension CampusViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
       if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.green
            return lineView
        } else if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.strokeColor = UIColor.blue
            polygonView.lineWidth = CGFloat(3.0)
            return polygonView
        }
        
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = POIAnnotationView(annotation: annotation, reuseIdentifier: "POI")
        annotationView.canShowCallout = true
        return annotationView
    }
}
