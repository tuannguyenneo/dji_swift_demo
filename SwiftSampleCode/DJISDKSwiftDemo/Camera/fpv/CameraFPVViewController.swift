//
//  CameraFPVViewController.swift
//  DJISDKSwiftDemo
//
//  Created by DJI on 2019/1/15.
//  Copyright © 2019 DJI. All rights reserved.
//

import UIKit
import DJISDK

var cameraHybridZoomSpec: DJICameraHybridZoomSpec?

class CameraFPVViewController: UIViewController {

    @IBOutlet weak var decodeModeSeg: UISegmentedControl!
    @IBOutlet weak var tempSwitch: UISwitch!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var fpvView: UIView!
    @IBOutlet var zoomLevel: UILabel!
    
    var adapter: VideoPreviewerAdapter?
    var needToSetMode = false
    
    var camera: DJICamera?
    var len: DJILens?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera = fetchCamera()
        self.camera = camera
        camera?.delegate = self
        
        needToSetMode = true
        configCameraForM300(nil)
        DJIVideoPreviewer.instance()?.start()
        
        adapter = VideoPreviewerAdapter.init()
        adapter?.start()
        
        if camera?.displayName == DJICameraDisplayNameMavic2ZoomCamera ||
            camera?.displayName == DJICameraDisplayNameDJIMini2Camera ||
            camera?.displayName == DJICameraDisplayNameMavicAir2Camera ||
            camera?.displayName == DJICameraDisplayNameDJIAir2SCamera ||
            camera?.displayName == DJICameraDisplayNameMavic2ProCamera {
        }
        adapter?.setupFrameControlHandler()
        
        if let lens = camera?.lenses.first {
            self.len = lens
            self.len?.delegate = self
            if lens.isHybridZoomSupported() {
                lens.getHybridZoomSpec { cameraHybridZoom, _ in
                    cameraHybridZoomSpec = cameraHybridZoom
                }
            }
        }
        
        setVideoStreamSource(type: .zoom)
    }

    private func setVideoStreamSource(type: DJICameraVideoStreamSource) {
        guard let product = DJISDKManager.product() as? DJIAircraft
        else { return }
        guard let camera = product.camera else { return }
        camera.setCameraVideoStreamSource(type) { (error) in
            if error == nil {
                print("Set Camera Stream Source to \(type) success!")
            } else {
                print("Set Camera Stream Source to \(type) failed!")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DJIVideoPreviewer.instance()?.setView(fpvView)
        updateThermalCameraUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Call unSetView during exiting to release the memory.
        DJIVideoPreviewer.instance()?.unSetView()
        
        if adapter != nil {
            adapter?.stop()
            adapter = nil
        }
    }
    
    @IBAction func onSwitchValueChanged(_ sender: UISwitch) {
        guard let camera = fetchCamera() else { return }
        self.camera = camera
        let mode: DJICameraThermalMeasurementMode = sender.isOn ? .spotMetering : .disabled
        camera.setThermalMeasurementMode(mode) { [weak self] (error) in
            if error != nil {
                self?.tempSwitch.setOn(false, animated: true)

                let alert = UIAlertController(title: nil, message: String(format: "Failed to set the measurement mode: %@", error?.localizedDescription ?? "unknown"), preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
                
                self?.present(alert, animated: true)
            }
        }
        
    }
    
    /**
     *  DJIVideoPreviewer is used to decode the video data and display the decoded frame on the view. DJIVideoPreviewer provides both software
     *  decoding and hardware decoding. When using hardware decoding, for different products, the decoding protocols are different and the hardware decoding is only supported by some products.
     */
    @IBAction func onSegmentControlValueChanged(_ sender: UISegmentedControl) {
        DJIVideoPreviewer.instance()?.enableHardwareDecode = sender.selectedSegmentIndex == 1
    }
    
    fileprivate func updateThermalCameraUI() {
        guard let camera = fetchCamera(),
        camera.isThermalCamera()
        else {
            tempSwitch.setOn(false, animated: false)
            return
        }
        
        camera.getThermalMeasurementMode { [weak self] (mode, error) in
            if error != nil {
                let alert = UIAlertController(title: nil, message: String(format: "Failed to set the measurement mode: %@", error?.localizedDescription ?? "unknown"), preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
                
                self?.present(alert, animated: true)
                
            } else {
                let enabled = mode != .disabled
                self?.tempSwitch.setOn(enabled, animated: true)
                
            }
        }
    }
    
    private func configCameraForM300(_ completion: ((Bool) -> Void)?) {
        guard let product = DJISDKManager.product() as? DJIAircraft,
              let listCamera = product.cameras,
              let airLink = product.airLink else {
            completion?(false)
            return
        }
        
        if airLink.isOcuSyncLinkSupported {
            if let ocuSync = airLink.ocuSyncLink {
                if listCamera.isEmpty {
                    ocuSync.assignSource(toPrimaryChannel: .fpvCamera, secondaryChannel: .rightCamera) { error in
                        if error != nil {
                            completion?(false)
                        }
                    }
                } else {
                    ocuSync.assignSource(toPrimaryChannel: .leftCamera, secondaryChannel: .fpvCamera) { error in
                        if error != nil {
                            completion?(false)
                        }
                    }
                }
                
                guard let camera = product.camera else {
                    completion?(false)
                    return
                }
                self.camera = camera
                let lenses = camera.lenses
                lenses.forEach { (lens) in
                    if lens.isAdjustableFocalPointSupported() {
                        // get exposure mode
                        lens.getExposureMode { mode, err in
                            if err == nil {
//                                self.cameraExposureMode = mode
                            }
                        }
                        self.len = lens
                    }
                }
                camera.getVideoStreamSource { [weak self] (streamSource, error) in
                    if error == nil {
                        switch streamSource {
                        case .wide:
                            print("Set Camera Stream Source to Wide success!")
                        case .zoom:
                            print("Set Camera Stream Source to Zoom success!")
                        case .infraredThermal:
                            print("Set Camera Stream Source to Infrared Thermal success!")
                        default:
                            self?.setVideoStreamSource(type: .wide)
                        }
                    } else {
                        print("Get Camera Stream Source failed!")
                    }
                }
                setDefaultCameraCaptureStreamSource(camera: camera)
                completion?(true)
            }
        }
    }
    
    private func setDefaultCameraCaptureStreamSource(camera: DJICamera?) {
        guard let camera = camera else { return }
        
        let listCameraSourceType: [DJICameraVideoStreamSource] = [.zoom, .wide, .infraredThermal]
        let captureStreams: [NSNumber]  = listCameraSourceType.map({NSNumber(value: $0.rawValue)})
        let cameraStreamSettings = DJICameraStreamSettings(needCurrentLiveView: false, streams: captureStreams )
        camera.setCaptureStreamSources(cameraStreamSettings, withCompletion: { error in
            if let error = error {
                print("setCaptureStreamSources: error = \(error)")
            } else {
                print("logg setCaptureStreamSources: Ok")
            }
        })
    }
}

/**
 *  DJICamera will send the live stream only when the mode is in DJICameraModeShootPhoto or DJICameraModeRecordVideo. Therefore, in order
 *  to demonstrate the FPV (first person view), we need to switch to mode to one of them.
 */
extension CameraFPVViewController: DJICameraDelegate {
    func camera(_ camera: DJICamera, didUpdate systemState: DJICameraSystemState) {
        if systemState.mode != .recordVideo && systemState.mode != .shootPhoto {
            return
        }
        if needToSetMode == false {
            return
        }
        needToSetMode = false
        self.setCameraMode(cameraMode: .shootPhoto)
        
    }
    
    func camera(_ camera: DJICamera, didUpdateTemperatureData temperature: Float) {
        tempLabel.text = String(format: "%f", temperature)
    }
    
}

extension CameraFPVViewController {
    fileprivate func fetchCamera() -> DJICamera? {
        guard let product = DJISDKManager.product() else {
            return nil
        }
        
        if product is DJIAircraft || product is DJIHandheld {
            return product.camera
        }
        return nil
    }
    
    fileprivate func setCameraMode(cameraMode: DJICameraMode = .shootPhoto) {
        var flatMode: DJIFlatCameraMode = .photoSingle
        let camera = self.fetchCamera()
        if camera?.isFlatCameraModeSupported() == true {
            NSLog("Flat camera mode detected")
            switch cameraMode {
            case .shootPhoto:
                flatMode = .photoSingle
            case .recordVideo:
                flatMode = .videoNormal
            default:
                flatMode = .photoSingle
            }
            camera?.setFlatMode(flatMode, withCompletion: { [weak self] (error: Error?) in
                if error != nil {
                    self?.needToSetMode = true
                    NSLog("Error set camera flat mode photo/video");
                }
            })
            } else {
                camera?.setMode(cameraMode, withCompletion: {[weak self] (error: Error?) in
                    if error != nil {
                        self?.needToSetMode = true
                        NSLog("Error set mode photo/video");
                    }
                })
            }
     }
}

extension CameraFPVViewController: DJILensDelegate {
    func lens(_ lens: DJILens, didUpdate state: DJICameraTapZoomState) {
        switch state {
        case .idle:
            if let cameraHybridZoomSpec = cameraHybridZoomSpec {
                lens.getHybridZoomFocalLength { [weak self] value, _ in
                    let cameraZoomLevel = cameraHybridZoomSpec.getZoomLevel(with: value)
                    self?.zoomLevel.text = "Magnification: \(cameraZoomLevel)\nFocal length: \(value)"
                }
            }
        default: break
        }
    }
}
