import UIKit
import CoreLocation
import MapKit

final class LocationPickerVC: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var destinationCoordinate: CLLocationCoordinate2D?
    private var isPickable = true
    let locationManager = CLLocationManager()
    
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        self.destinationCoordinate = coordinates
        self.isPickable = coordinates == nil
        super.init(nibName: nil, bundle: nil)
    }
    
    // Question: Why need this function?
    // Anwser: Key Coding Compliance for NSCoding for the decoder
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isPickable {
            // Pickable: send location Message
            view.backgroundColor = .systemBackground
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(sendButtonTapped))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self,
                                                 action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        } else {
            // Not Pickable(Click the location Message): just showing location user pass in
            guard let coordinates = destinationCoordinate else {
                return
            }
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: coordinates, span: span)
            map.setRegion(region, animated: true)
            // drop a pin on that location
            let annotation = MyAnnotation(coordinate: coordinates)
            annotation.title = "Destination"
            annotation.subtitle = "Come Here"
            map.addAnnotation(annotation)
        }
        view.addSubview(map)
        map.delegate = self
    }
    
    @objc func sendButtonTapped() {
        guard let coordinates = destinationCoordinate else {
            return
        }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    
    @objc func didTapMap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.destinationCoordinate = coordinates
        
        for annotation in map.annotations {  // remove prior anotation
            map.removeAnnotation(annotation)
        }
        // drop a pin on that location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
}

class MyAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
extension LocationPickerVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // give notation name
        let destinationID = "Destination"
        var result = map.dequeueReusableAnnotationView(withIdentifier: destinationID)
        // no annotation can reuse -> make a new one
        if result == nil {
            result = MKPinAnnotationView(annotation: annotation, reuseIdentifier: destinationID)
        } else {
            // annotation = prior make by let annotation = MyAnnotation(coordinate: coordinates)
            result?.annotation = annotation
        }
        result?.canShowCallout = true
        
        // Right callout accessoyr view.
        let button = UIButton(type: .detailDisclosure) // "i"
        button.addTarget(self, action: #selector(infoBtnPressed(sender:)), for: .touchUpInside)
        result?.rightCalloutAccessoryView = button
        
        return result
    }
    
    @objc func infoBtnPressed(sender: UIButton){
        let alert = UIAlertController(title: "Destination",
                                      message: "Navigate to here？",
                                      preferredStyle: .alert)
        let ok = UIAlertAction(title: "Yes", style: .default) { action in
            self.navigateTo()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    func navigateTo() {
        
        // Prepare target map item.
        guard let targetCoordinate = destinationCoordinate else {
            return
        }
        let targetPlacemark = MKPlacemark(coordinate: targetCoordinate)
        let targetMapItem = MKMapItem(placemark: targetPlacemark)
        
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
 
        let items = [targetMapItem]
        MKMapItem.openMaps(with: items, launchOptions: options)
    }
}

