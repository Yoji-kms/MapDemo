//
//  ViewController.swift
//  MapDemo
//
//  Created by Yoji on 17.11.2024.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    private let locationManager = CLLocationManager()
    private var sourceCoordinate: CLLocationCoordinate2D?
    
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.mapType = .standard
        map.showsCompass = true
        map.showsUserLocation = true
        map.showsUserTrackingButton = true
        map.delegate = self
        
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    private lazy var clearAllPointsButton: UIButton = {
        let button = UIButton()
        let text = String(localized: "Clear all")
        button.backgroundColor = .white
        button.setTitle(text, for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(self.clearAllPointsButtonDidTap), for: .touchUpInside)
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.setupGestures()
        self.setupStartLocation()
    }

    private func setupViews() {
        self.view.addSubview(self.mapView)
        self.view.addSubview(self.clearAllPointsButton)
        
        NSLayoutConstraint.activate([
            self.mapView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            self.clearAllPointsButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16),
            self.clearAllPointsButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        self.mapView.addGestureRecognizer(longPress)
    }
    
    private func setupStartLocation() {
        self.requestLocation()
        
        guard let currentLocation = self.locationManager.location?.coordinate else { return }
        self.mapView.region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 10000, longitudinalMeters: 10000)
    }
    
    private func requestLocation() {
        if self.locationManager.authorizationStatus == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    @objc private func clearAllPointsButtonDidTap() {
        self.mapView.removeAll()
    }
    
    @objc private func longPressAction(sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: self.mapView)
        let tappedCoordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
        
        if self.locationManager.authorizationStatus != .denied {
            let currentCoordinate = self.locationManager.location?.coordinate
            
            self.sourceCoordinate = self.sourceCoordinate == currentCoordinate ? self.sourceCoordinate : currentCoordinate
            
            guard let unwrappedSourceCoordinate = self.sourceCoordinate else { return }
            
            let startTitle = String(localized: "Start")
            self.mapView.addAnnotationWith(coordinate: unwrappedSourceCoordinate, title: startTitle)
            
            let endTitle = String(localized: "End")
            self.mapView.addAnnotationWith(coordinate: tappedCoordinate, title: endTitle)
            
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: unwrappedSourceCoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: tappedCoordinate))
            
            let direction = MKDirections(request: request)
            direction.calculate() { [weak self] response, error in
                guard let self, let response, let route = response.routes.first else { return }
                self.mapView.addOverlay(route.polyline)
            }
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let render = MKPolylineRenderer(overlay: overlay)
            render.strokeColor = .systemOrange
            render.lineWidth = 5
            return render
        }
        return MKOverlayRenderer()
    }
}

extension MKMapView {
    func addAnnotationWith(coordinate: CLLocationCoordinate2D, title: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        self.addAnnotation(annotation)
    }
    
    func removeAll() {
        let annotations = self.annotations
        self.removeAnnotations(annotations)
        
        let overlays = self.overlays
        self.removeOverlays(overlays)
    }
}

extension CLLocationCoordinate2D? {
    static func ==(lhs: CLLocationCoordinate2D?, rhs: CLLocationCoordinate2D?) -> Bool {
        return lhs?.latitude == rhs?.latitude && lhs?.longitude == rhs?.longitude
    }
}
