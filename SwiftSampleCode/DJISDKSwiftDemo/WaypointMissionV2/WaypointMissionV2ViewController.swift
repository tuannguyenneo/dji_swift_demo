//
//  WaypointMissionV2ViewController.swift
//  DJISDKSwiftDemo
//
//  Created by Tuan Nguyen on 15/09/2022.
//  Copyright © 2022 DJI. All rights reserved.
//

import UIKit
import DJISDK
import CoreLocation

enum WaypointV2Action {
    case STAY
    case START_MOVING
    case TAKE_PHOTO
    case START_RECORD
    case STOP_RECORD
    case ROTATE_HEADING
    case ROTATE_GIMBAL
    case ROTATE_GIMBAL_ONLINE
    case ROTATE_GIMBAL_PAN
    case REACH_POINT
    case START_INTERVAL_SHOOTING
    case STOP_INTERVAL_SHOOTING
    case ZOOM
}

// MARK: - DJICameraHybridZoomSpec
extension DJICameraHybridZoomSpec {
    func getFocalLength(with zoom: Double) -> UInt {
        let maxZoom = getMaxZoom()
        if zoom > maxZoom {
            return maxHybridFocalLength
        } else {
            return UInt((3 * zoom * Double(minHybridFocalLength))/4)
        }
    }
    
    func getZoomLevel(with focalLength: UInt) -> Double {
        if focalLength > maxHybridFocalLength {
            return getMaxZoom()
        } else {
            return 4 * Double(focalLength)/(3 * Double(minHybridFocalLength))
        }
    }

    func getMaxZoom() -> Double {
        return Double(maxHybridFocalLength) / Double(minHybridFocalLength)
    }
}

class TIWaypointV2Action: DJIWaypointV2Action {
    let type: WaypointV2Action
    
    init(type: WaypointV2Action) {
        self.type = type
        super.init()
    }
}

final class WaypointMissionV2ViewController: UIViewController {
    var missionV2Operator: DJIWaypointV2MissionOperator! {
        DJISDKManager.missionControl()!.waypointV2MissionOperator()
    }
    
    var cameraVC: CameraFPVViewController?
    var backupListActionsV2 = [DJIWaypointV2Action]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DJISDKManager.product()?.camera?.delegate = self
        
        view.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.view.isUserInteractionEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CameraFPVViewController {
            cameraVC = vc
        }
    }
    
    @IBAction func loadMission(_ sender: Any) {
        print("===> Load mission")
        loadMission()
    }
    
    @IBAction func startMission(_ sender: Any) {
        missionV2Operator.startMission { error in
            print("===> Start mission: error = \(String(describing: error))")
        }
    }
    
    @IBAction func stopMission(_ sender: Any) {
        missionV2Operator.stopMission { error in
            print("===> Stop mission: error = \(String(describing: error))")
        }
    }
    
    func loadMission() {
        var listWaypointsV2 = [DJIWaypointV2]()
        var listActionsV2 = [DJIWaypointV2Action]()
        var actionIndex = 0
        
        // 1 ---------------
        let firstWP = DJIWaypointV2()
        firstWP.coordinate = CLLocationCoordinate2D(latitude: 33.6209929, longitude: 130.6265251)
//        firstWP.heading = 30
        firstWP.altitude = 20
        firstWP.headingMode = .fixed
        firstWP.autoFlightSpeed = Float(3)
        firstWP.isUsingWaypointAutoFlightSpeed = true
        
        listWaypointsV2.append(firstWP)
        // reach point
        let reachPointAction = createWaypointV2Action(action: .REACH_POINT,
                                                      actionIndex: actionIndex,
                                                      waypointIndex: 0)
        actionIndex = reachPointAction.newActionIndex
        listActionsV2.append(reachPointAction.waypointAction)
       
        // interval shooting
//        let intervalShootingAction = createWaypointV2Action(action: .START_INTERVAL_SHOOTING,
//                                                            actionIndex: actionIndex,
//                                                            waypointIndex: 0)
//        actionIndex = intervalShootingAction.newActionIndex
//        listActionsV2.append(intervalShootingAction.waypointAction)
        
        // rotate heading
//        let headingAction = createWaypointV2Action(action: .ROTATE_HEADING,
//                                                   actionIndex: actionIndex,
//                                                   waypointIndex: 0,
//                                                   heading: 308.1)
//        actionIndex = headingAction.newActionIndex
//        listActionsV2.append(headingAction.waypointAction)
        
        // Zoom
        // 2X --> 15X:
        if let zoomRate2XToFocalLength = cameraHybridZoomSpec?.getFocalLength(with: 2.0) {
            let zoomAction2X = createWaypointV2Action(action: .ZOOM, actionIndex: actionIndex, zoom: Double(zoomRate2XToFocalLength))
            actionIndex = zoomAction2X.newActionIndex
            listActionsV2.append(zoomAction2X.waypointAction)
        }
        
        if let zoomRate15XToFocalLength = cameraHybridZoomSpec?.getFocalLength(with: 15.0) {
            let zoomAction15X = createWaypointV2Action(action: .ZOOM, actionIndex: actionIndex, zoom: Double(zoomRate15XToFocalLength))
            actionIndex = zoomAction15X.newActionIndex
            listActionsV2.append(zoomAction15X.waypointAction)
        }
        
        // stay
        let makeDroneStayAction = createWaypointV2Action(action: .STAY,
                                                         actionIndex: actionIndex,
                                                         stay: 3)
        actionIndex = makeDroneStayAction.newActionIndex
        listActionsV2.append(makeDroneStayAction.waypointAction)
        // moving
        let startMovingAction = createWaypointV2Action(action: .START_MOVING,
                                                       actionIndex: actionIndex)
        actionIndex = startMovingAction.newActionIndex
        listActionsV2.append(startMovingAction.waypointAction)
        
        // 2 ---------------
        let secondWP = DJIWaypointV2()
        secondWP.coordinate = CLLocationCoordinate2D(latitude: 33.6211096, longitude: 130.6265459)
//        secondWP.heading = 90
        secondWP.altitude = 15
        secondWP.headingMode = .fixed
        secondWP.autoFlightSpeed = Float(3)
        secondWP.isUsingWaypointAutoFlightSpeed = true
        
        listWaypointsV2.append(secondWP)
        // reach point
        let reachPointAction2 = createWaypointV2Action(action: .REACH_POINT,
                                                       actionIndex: actionIndex,
                                                       waypointIndex: 1)
        actionIndex = reachPointAction2.newActionIndex
        listActionsV2.append(reachPointAction2.waypointAction)
        
        // heading
        let headingAction2 = createWaypointV2Action(action: .ROTATE_HEADING,
                                                    actionIndex: actionIndex,
                                                    waypointIndex: 1,
                                                    heading: 131)
        actionIndex = headingAction2.newActionIndex
        listActionsV2.append(headingAction2.waypointAction)
        
        // 2X --> 23X:
        if let zoomRate2XToFocalLength = cameraHybridZoomSpec?.getFocalLength(with: 2.0) {
            let zoomAction2X = createWaypointV2Action(action: .ZOOM, actionIndex: actionIndex, zoom: Double(zoomRate2XToFocalLength))
            actionIndex = zoomAction2X.newActionIndex
            listActionsV2.append(zoomAction2X.waypointAction)
        }
        
        if let zoomRate23XToFocalLength = cameraHybridZoomSpec?.getFocalLength(with: 23.0) {
            let zoomAction23X = createWaypointV2Action(action: .ZOOM, actionIndex: actionIndex, zoom: Double(zoomRate23XToFocalLength))
            actionIndex = zoomAction23X.newActionIndex
            listActionsV2.append(zoomAction23X.waypointAction)
        }
        
        // stay
        let makeDroneStayAction2 = createWaypointV2Action(action: .STAY,
                                                          actionIndex: actionIndex,
                                                          stay: 3)
        actionIndex = makeDroneStayAction2.newActionIndex
        listActionsV2.append(makeDroneStayAction2.waypointAction)
        // moving
        let startMovingAction2 = createWaypointV2Action(action: .START_MOVING,
                                                        actionIndex: actionIndex)
        actionIndex = startMovingAction2.newActionIndex
        listActionsV2.append(startMovingAction2.waypointAction)
        
        // Gimbal tilt
        let gimbalAction2 = createWaypointV2Action(action: .ROTATE_GIMBAL_ONLINE,
                                                            actionIndex: actionIndex,
                                                            waypointIndex: 1,
                                                            gimbal: -60)
        actionIndex = gimbalAction2.newActionIndex
        listActionsV2.append(gimbalAction2.waypointAction)
        
        // 3 ---------------
        let thirdWP = DJIWaypointV2()
        thirdWP.coordinate = CLLocationCoordinate2D(latitude: 33.6211166, longitude: 130.6263363)
//        thirdWP.heading = 40
        thirdWP.altitude = 18
        thirdWP.headingMode = .fixed
        thirdWP.autoFlightSpeed = Float(3)
        thirdWP.isUsingWaypointAutoFlightSpeed = true
        
        listWaypointsV2.append(thirdWP)
        // reach point
        let reachPointAction3 = createWaypointV2Action(action: .REACH_POINT,
                                                       actionIndex: actionIndex,
                                                       waypointIndex: 2)
        actionIndex = reachPointAction3.newActionIndex
        listActionsV2.append(reachPointAction3.waypointAction)
        
        // heading
        let headingAction3 = createWaypointV2Action(action: .ROTATE_HEADING,
                                                    actionIndex: actionIndex,
                                                    waypointIndex: 2,
                                                    heading: 308)
        actionIndex = headingAction3.newActionIndex
        listActionsV2.append(headingAction3.waypointAction)
        
        // stay
        let makeDroneStayAction3 = createWaypointV2Action(action: .STAY,
                                                          actionIndex: actionIndex,
                                                          stay: 2)
        actionIndex = makeDroneStayAction3.newActionIndex
        listActionsV2.append(makeDroneStayAction3.waypointAction)
        // moving
        let startMovingAction3 = createWaypointV2Action(action: .START_MOVING,
                                                        actionIndex: actionIndex)
        actionIndex = startMovingAction3.newActionIndex
        listActionsV2.append(startMovingAction3.waypointAction)
        
        
        
        // 4 ----------------
        let fourthWP = DJIWaypointV2()
        fourthWP.coordinate = CLLocationCoordinate2D(latitude: 33.6210214, longitude: 130.6262254)
//        fourthWP.heading = 60
        fourthWP.altitude = 12
        fourthWP.headingMode = .fixed
        fourthWP.autoFlightSpeed = Float(3)
        fourthWP.isUsingWaypointAutoFlightSpeed = true
        
        listWaypointsV2.append(fourthWP)
        // reach point
        let reachPointAction4 = createWaypointV2Action(action: .REACH_POINT,
                                                       actionIndex: actionIndex,
                                                       waypointIndex: 3)
        actionIndex = reachPointAction4.newActionIndex
        listActionsV2.append(reachPointAction4.waypointAction)
        
        // heading
        let headingAction4 = createWaypointV2Action(action: .ROTATE_HEADING,
                                                    actionIndex: actionIndex,
                                                    waypointIndex: 3,
                                                    heading: 131)
        actionIndex = headingAction4.newActionIndex
        listActionsV2.append(headingAction4.waypointAction)
        
        // stay
        let makeDroneStayAction4 = createWaypointV2Action(action: .STAY,
                                                          actionIndex: actionIndex,
                                                          stay: 2)
        actionIndex = makeDroneStayAction4.newActionIndex
        listActionsV2.append(makeDroneStayAction4.waypointAction)
        // moving
        let startMovingAction4 = createWaypointV2Action(action: .START_MOVING,
                                                        actionIndex: actionIndex)
        actionIndex = startMovingAction4.newActionIndex
        listActionsV2.append(startMovingAction4.waypointAction)
        
        backupListActionsV2 = listActionsV2
        
        let tempMissionV2 = DJIMutableWaypointV2Mission()
        tempMissionV2.maxFlightSpeed = Float(5)
        tempMissionV2.finishedAction = .noAction
        tempMissionV2.gotoFirstWaypointMode = .safely
        tempMissionV2.exitMissionOnRCSignalLost = true
        tempMissionV2.autoFlightSpeed = Float(5)
        tempMissionV2.repeatTimes = 1
        tempMissionV2.addWaypoints(listWaypointsV2)
        
        let missionV2 = DJIWaypointV2Mission(mission: tempMissionV2)
        missionV2Operator.removeAllListeners()
        missionV2Operator.load(missionV2) { error in
            print("===> load mission error: \(error)")
            
            // upload mission
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                if self.missionV2Operator.currentState == .readyToUpload {
                    self.missionV2Operator.uploadMission { error in
                        if let error = error {
                            print("===> upload mission failed: error = \(error)")
                        } else {
                            print("===> upload mission succeed")
                        }
                    }
                }
            }
            
            guard error == nil else { return }
            
            self.missionV2Operator.addListener(toExecutionEvent: self, with: .main) { event in
                
            }
            
            self.missionV2Operator.addListener(toActionUploadEvent: self, with: .main) { event in
                if event.currentState == .readyToUpload {
                    // upload actions
                    self.missionV2Operator.uploadWaypointActions(listActionsV2) { error in
                        print("===> upload actions: error = \(String(describing: error)) - number of actions = \(listActionsV2.count)")
                    }
                } else if event.previousState == .uploading
                            && event.currentState == .readyToExecute {
                    print("===> Mission V2 ready to EXECUTE")
                }
            }
            
            self.missionV2Operator.addListener(toActionExecutionEvent: self, with: .main) { [weak self] event in
                guard let self = self else { return }
                if event.error != nil {
                    let errCode = String((event.error! as NSError).code)
                    print("===> Error code: \(errCode) - \(event.error.debugDescription)")
                }
                if let progress = event.progress {
                    let actionID = progress.actionId
                    if let wpAction = self.backupListActionsV2.first(where: { $0.actionId == actionID }) as? TIWaypointV2Action {
                        print("===>> toActionExecutionEvent action type = \(wpAction.type) - actionID = \(actionID)")
                    }
                }
            }
            
            self.missionV2Operator.addListener(toExecutionEvent: self, with: .main, andBlock: { event in
                if let error = event.error {
                    print("===>> execution action failed: \(error)")
                } else {
                    
                    print("===>> execution action succeed \(event.description)")
                    if event.progress?.isWaypointReached == true,
                       let targetIndex = event.progress?.targetWaypointIndex {
                        print("===>> Reached wp index = \(targetIndex)")
                    }
                }
            })
            
            self.missionV2Operator.addListener(toFinished: self, with: .main) { error in
                self.missionV2Operator.removeAllListeners()
                if let error = error {
                    print("===>> Mission finished failed: \(error)")
                } else {
                    print("===>> Mission finished succeed")
                }
            }
        }
    }
    
    func createWaypointV2Action(action: WaypointV2Action,
                                actionIndex: Int,
                                waypointIndex: Int = 0,
                                heading: Float = 0.0,
                                gimbal: Int = 0,
                                stay: Double = 0.0,
                                intervalTime: Double = 0.0,
                                zoom: Double = 0.0) -> (newActionIndex: Int, waypointAction: DJIWaypointV2Action) {
        var newActionIndex = actionIndex
        switch action {
        case .REACH_POINT:
            // Reach waypoint: - Trigger Param
            let reachPointTriggerParam = DJIWaypointV2ReachPointTriggerParam()
            reachPointTriggerParam.startIndex = UInt(waypointIndex)
            reachPointTriggerParam.waypointCountToTerminate = UInt(waypointIndex)
            
            let reachPointTrigger = DJIWaypointV2Trigger()
            reachPointTrigger.actionTriggerType = .reachPoint
            reachPointTrigger.reachPointTriggerParam = reachPointTriggerParam
            
            // Reach waypoint: - Actuator Param
            let flyControlParam = DJIWaypointV2AircraftControlFlyingParam()
            flyControlParam.isStartFlying = false
            
            let reachPointActuatorParam = DJIWaypointV2AircraftControlParam()
            reachPointActuatorParam.operationType = .flyingControl
            reachPointActuatorParam.flyControlParam = flyControlParam
            
            let reachPointActuator = DJIWaypointV2Actuator()
            reachPointActuator.type = .aircraftControl
            reachPointActuator.aircraftControlActuatorParam = reachPointActuatorParam
            
            // Reach waypoint: - Combine Trigger & Actuator
            if newActionIndex != 0 {
                newActionIndex += 1
            }
            let reachPointAction = TIWaypointV2Action(type: .REACH_POINT)
            reachPointAction.actionId = UInt(newActionIndex)
            reachPointAction.trigger = reachPointTrigger
            reachPointAction.actuator = reachPointActuator
            
            return (newActionIndex, reachPointAction)
        case .ROTATE_GIMBAL:
            // GIMBAL_TILT - trigger
            let triggerParam = DJIWaypointV2AssociateTriggerParam()
            triggerParam.actionIdAssociated = UInt(newActionIndex)
            triggerParam.actionAssociatedType = .afterFinished
            triggerParam.waitingTime = UInt(3)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .actionAssociated
            trigger.associateTriggerParam = triggerParam
            
            // GIMBAL_TILT - actuator
            let actuatorParam = DJIWaypointV2GimbalActuatorParam()
            actuatorParam.operationType = .rotateGimbal
            if abs(gimbal) == 90 {
                actuatorParam.rotation = DJIGimbalRotation(pitchValue: -90,
                                                           rollValue: 0,
                                                           yawValue: nil,
                                                           time: 3.0,
                                                           mode: .absoluteAngle,
                                                           ignore: true)
            } else {
                actuatorParam.rotation = DJIGimbalRotation(pitchValue: NSNumber(value: gimbal),
                                                           rollValue: 0,
                                                           yawValue: nil,
                                                           time: 3.0,
                                                           mode: .absoluteAngle,
                                                           ignore: true)
            }
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .gimbal
            actuator.gimbalActuatorParam = actuatorParam
            
            // GIMBAL_TILT - combine
            newActionIndex += 1
            
            let rotateGimbalAction = TIWaypointV2Action(type: .ROTATE_GIMBAL)
            rotateGimbalAction.actionId = UInt(newActionIndex)
            rotateGimbalAction.trigger = trigger
            rotateGimbalAction.actuator = actuator
            
            return (newActionIndex, rotateGimbalAction)
        case .ROTATE_GIMBAL_PAN:
            // GIMBAL_PAN - trigger
            let triggerParam = DJIWaypointV2AssociateTriggerParam()
            triggerParam.actionIdAssociated = UInt(newActionIndex)
            triggerParam.actionAssociatedType = .afterFinished
            triggerParam.waitingTime = UInt(3)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .actionAssociated
            trigger.associateTriggerParam = triggerParam
            
            // GIMBAL_PAN - actuator
            let actuatorParam = DJIWaypointV2GimbalActuatorParam()
            actuatorParam.operationType = .rotateGimbal
            actuatorParam.rotation = DJIGimbalRotation(pitchValue: nil,
                                                       rollValue: 0,
                                                       yawValue: NSNumber(value: gimbal),
                                                       time: 3.0,
                                                       mode: .absoluteAngle,
                                                       ignore: true)
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .gimbal
            actuator.gimbalActuatorParam = actuatorParam
            
            // GIMBAL_TILT - combine
            newActionIndex += 1
            
            let rotateGimbalAction = TIWaypointV2Action(type: .ROTATE_GIMBAL_PAN)
            rotateGimbalAction.actionId = UInt(newActionIndex)
            rotateGimbalAction.trigger = trigger
            rotateGimbalAction.actuator = actuator
            
            return (newActionIndex, rotateGimbalAction)
        case .ROTATE_HEADING:
            var heading = heading
            if heading > 180 {
                heading -= 360
            }
            if heading < -180 {
                heading += 360
            }
            
            // HEADING - Trigger:
            let triggerParam = DJIWaypointV2AssociateTriggerParam()
            triggerParam.actionIdAssociated = UInt(newActionIndex)
            triggerParam.actionAssociatedType = .afterFinished
            triggerParam.waitingTime = UInt(5)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .actionAssociated
            trigger.associateTriggerParam = triggerParam
            
            // HEADING - Actuator:
            let rotateDroneHeadingActuatorParam = DJIWaypointV2AircraftControlRotateHeadingParam()
            rotateDroneHeadingActuatorParam.isRelative = false
            rotateDroneHeadingActuatorParam.direction = .clockwise
            rotateDroneHeadingActuatorParam.heading = heading
            
            let aircraftControlActuatorParam = DJIWaypointV2AircraftControlParam()
            aircraftControlActuatorParam.operationType = .rotateYaw
            aircraftControlActuatorParam.yawRotatingParam = rotateDroneHeadingActuatorParam
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .aircraftControl
            actuator.aircraftControlActuatorParam = aircraftControlActuatorParam
            
            // HEADING - Combine:
            newActionIndex += 1
            
            let rotateHeadingAction = TIWaypointV2Action(type: .ROTATE_HEADING)
            rotateHeadingAction.actionId = UInt(newActionIndex)
            rotateHeadingAction.trigger = trigger
            rotateHeadingAction.actuator = actuator
            
            return (newActionIndex, rotateHeadingAction)
        case .START_RECORD:
            // START_RECORD - trigger:
            let triggerParam = DJIWaypointV2AssociateTriggerParam()
            triggerParam.actionIdAssociated = UInt(newActionIndex)
            triggerParam.actionAssociatedType = .afterFinished
            triggerParam.waitingTime = UInt(3)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .actionAssociated
            trigger.associateTriggerParam = triggerParam
            
            // START_RECORD - actuator:
            let actuatorParam = DJIWaypointV2CameraActuatorParam()
            actuatorParam.operationType = .startRecordVideo
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .camera
            actuator.cameraActuatorParam = actuatorParam
            
            // START_RECORD - combine:
            newActionIndex += 1
            
            let startRecordAction = TIWaypointV2Action(type: .START_RECORD)
            startRecordAction.actionId = UInt(newActionIndex)
            startRecordAction.trigger = trigger
            startRecordAction.actuator = actuator
            
            return (newActionIndex, startRecordAction)
        case .STOP_RECORD:
            // STOP_RECORD - trigger:
            let triggerParam = DJIWaypointV2AssociateTriggerParam()
            triggerParam.actionIdAssociated = UInt(newActionIndex)
            triggerParam.actionAssociatedType = .afterFinished
            triggerParam.waitingTime = UInt(3)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .actionAssociated
            trigger.associateTriggerParam = triggerParam
            
            // STOP_RECORD - actuator:
            let actuatorParam = DJIWaypointV2CameraActuatorParam()
            actuatorParam.operationType = .stopRecordVideo
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .camera
            actuator.cameraActuatorParam = actuatorParam
            
            // STOP_RECORD - combine:
            newActionIndex += 1
            
            let stopRecordAction = TIWaypointV2Action(type: .STOP_RECORD)
            stopRecordAction.actionId = UInt(newActionIndex)
            stopRecordAction.trigger = trigger
            stopRecordAction.actuator = actuator
            
            return (newActionIndex, stopRecordAction)
        case .STAY:
            // HOVERING - Trigger: Make drone stop moving
            let triggerParam = DJIWaypointV2AssociateTriggerParam()
            triggerParam.actionIdAssociated = UInt(newActionIndex)
            triggerParam.actionAssociatedType = .afterFinished
            triggerParam.waitingTime = UInt(stay)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .actionAssociated
            trigger.associateTriggerParam = triggerParam
            
            // HOVERING - Actuator: Make drone stop moving
            let flyControlParam = DJIWaypointV2AircraftControlFlyingParam()
            flyControlParam.isStartFlying = false
            
            let actuatorParam = DJIWaypointV2AircraftControlParam()
            actuatorParam.operationType = .flyingControl
            actuatorParam.flyControlParam = flyControlParam
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .aircraftControl
            actuator.aircraftControlActuatorParam = actuatorParam
            
            // HOVERING - Combine Trigger & Actuator: Make drone stop moving
            newActionIndex += 1
            
            let stayAction = TIWaypointV2Action(type: .STAY)
            stayAction.actionId = UInt(newActionIndex)
            stayAction.trigger = trigger
            stayAction.actuator = actuator
            
            return (newActionIndex, stayAction)
        case .START_MOVING:
            // START_MOVING - Trigger:
            let triggerParam = DJIWaypointV2AssociateTriggerParam()
            triggerParam.actionIdAssociated = UInt(newActionIndex)
            triggerParam.actionAssociatedType = .afterFinished
            triggerParam.waitingTime = UInt(5)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .actionAssociated
            trigger.associateTriggerParam = triggerParam
            
            // START_MOVING - Actuator:
            let flyControlParam = DJIWaypointV2AircraftControlFlyingParam()
            flyControlParam.isStartFlying = true
            
            let actuatorParam = DJIWaypointV2AircraftControlParam()
            actuatorParam.operationType = .flyingControl
            actuatorParam.flyControlParam = flyControlParam
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .aircraftControl
            actuator.aircraftControlActuatorParam = actuatorParam
            
            // START_MOVING - Combine Trigger & Actuator: Make drone start moving
            newActionIndex += 1
            
            let startMovingAction = TIWaypointV2Action(type: .START_MOVING)
            startMovingAction.actionId = UInt(newActionIndex)
            startMovingAction.trigger = trigger
            startMovingAction.actuator = actuator
            
            return (newActionIndex, startMovingAction)
        case .TAKE_PHOTO:
            // IMAGE_SHOOTING - trigger:
            let triggerParam = DJIWaypointV2AssociateTriggerParam()
            triggerParam.actionIdAssociated = UInt(newActionIndex)
            triggerParam.actionAssociatedType = .afterFinished
            triggerParam.waitingTime = UInt(3)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .actionAssociated
            trigger.associateTriggerParam = triggerParam
            
            // IMAGE_SHOOTING - actuator:
            let actuatorParam = DJIWaypointV2CameraActuatorParam()
            actuatorParam.operationType = .takePhoto
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .camera
            actuator.cameraActuatorParam = actuatorParam
            
            // IMAGE_SHOOTING - combine:
            newActionIndex += 1
            
            let takePhotoAction = TIWaypointV2Action(type: .TAKE_PHOTO)
            takePhotoAction.actionId = UInt(newActionIndex)
            takePhotoAction.trigger = trigger
            takePhotoAction.actuator = actuator
            
            return (newActionIndex, takePhotoAction)
        case .START_INTERVAL_SHOOTING:
            // START_INTERVAL - trigger:
            let triggerParam = DJIWaypointV2IntervalTriggerParam()
            triggerParam.actionIntervalType = .time
            triggerParam.interval = Float(intervalTime)
            triggerParam.startIndex = UInt(waypointIndex)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .interval
            trigger.intervalTriggerParam = triggerParam
            
            // START_INTERVAL - actuator:
            let actuatorParam = DJIWaypointV2CameraActuatorParam()
            actuatorParam.operationType = .takePhoto
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .camera
            actuator.cameraActuatorParam = actuatorParam
            
            // START_INTERVAL - combine:
            newActionIndex += 1
            
            let intervalShootingAction = TIWaypointV2Action(type: .START_INTERVAL_SHOOTING)
            intervalShootingAction.actionId = UInt(newActionIndex)
            intervalShootingAction.trigger = trigger
            intervalShootingAction.actuator = actuator
            
            return (newActionIndex, intervalShootingAction)
        case .STOP_INTERVAL_SHOOTING:
            break
        case .ZOOM:
            let triggerParam = DJIWaypointV2AssociateTriggerParam()
            triggerParam.actionIdAssociated = UInt(newActionIndex)
            triggerParam.actionAssociatedType = .afterFinished
            triggerParam.waitingTime = UInt(0)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .actionAssociated
            trigger.associateTriggerParam = triggerParam
            
            // ZOOM - actuator:
            let zoomParam = DJIWaypointV2CameraFocalLengthParam()
            zoomParam.focalLength = UInt(zoom)
            let actuatorParam = DJIWaypointV2CameraActuatorParam()
            actuatorParam.operationType = .zoom
            actuatorParam.zoomParam = zoomParam
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .camera
            actuator.cameraActuatorParam = actuatorParam
            
            // START_INTERVAL - combine:
            newActionIndex += 1
            
            let intervalShootingAction = TIWaypointV2Action(type: .ZOOM)
            intervalShootingAction.actionId = UInt(newActionIndex)
            intervalShootingAction.trigger = trigger
            intervalShootingAction.actuator = actuator
            
            return (newActionIndex, intervalShootingAction)
        case .ROTATE_GIMBAL_ONLINE:
            var newIndex = actionIndex
            let triggerParam = DJIWaypointV2TrajectoryTriggerParam()
            triggerParam.startIndex = UInt(waypointIndex)
            triggerParam.endIndex = UInt(waypointIndex + 1)
            
            let trigger = DJIWaypointV2Trigger()
            trigger.actionTriggerType = .trajectory
            trigger.trajectoryTriggerParam = triggerParam
            
            // GIMBAL_TILT - actuator
            var actuatorParam = DJIWaypointV2GimbalActuatorParam()
            actuatorParam.operationType = .aircraftControlGimbal
            
            var gimbalTilt = gimbal
            if abs(gimbalTilt) == 90 {
                gimbalTilt = -90
            }
            actuatorParam.rotation = DJIGimbalRotation(pitchValue: NSNumber(value: gimbalTilt),
                                                       rollValue: 0,
                                                       yawValue: 0,
                                                       time: 3.0,
                                                       mode: .absoluteAngle,
                                                       ignore: false)
            
            let actuator = DJIWaypointV2Actuator()
            actuator.type = .gimbal
            actuator.gimbalActuatorParam = actuatorParam
            
            newIndex += 1
            let rotateGimbalAction = TIWaypointV2Action(type: .ROTATE_GIMBAL_ONLINE)
            rotateGimbalAction.actionId = UInt(newIndex)
            rotateGimbalAction.trigger = trigger
            rotateGimbalAction.actuator = actuator
            return (newIndex, rotateGimbalAction)
        }
        return (-1, DJIWaypointV2Action())
    }
}

extension WaypointMissionV2ViewController: DJICameraDelegate {
    func camera(_ camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMediaFile) {
        print("New 🌇: \(newMedia.fileName)")
    }
}
