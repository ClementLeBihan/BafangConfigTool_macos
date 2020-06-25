//
//  BafangInteraction.swift
//  BafangConfigTool
//
//  Created by Clément Le Bihan on 15/06/2020.
//  Copyright © 2020 Clément Le Bihan. All rights reserved.
//

import Foundation
import SwiftUI

/******** INFO MESSAGE ********/
class InfoMessage {
    @Published var manufacturer: String = ""
    @Published var model: String = ""
    @Published var HWVersion: String = ""
    @Published var FWVersion: String = ""
    @Published var voltage: String = ""
    @Published var maxCurrent: String = ""
    
    let voltageMap = ["24", "36", "48", "60", "24-48", "24-60"]
    
    init(){
        
    }
    
    init(msg: [UInt8])
    {
            manufacturer = String(decoding: msg[msg.index(msg.startIndex, offsetBy: 2)..<msg.index(msg.startIndex, offsetBy: 6)], as: UTF8.self)

            model = String(decoding: msg[msg.index(msg.startIndex, offsetBy: 6)..<msg.index(msg.startIndex, offsetBy: 10)], as: UTF8.self)
            
            HWVersion = "V" + String(decoding: msg[msg.index(msg.startIndex, offsetBy: 10)..<msg.index(msg.startIndex, offsetBy: 11)], as: UTF8.self) + "." + String(decoding: msg[msg.index(msg.startIndex, offsetBy: 11)..<msg.index(msg.startIndex, offsetBy: 12)], as: UTF8.self)
            
            FWVersion = "V" + String(decoding: msg[msg.index(msg.startIndex, offsetBy: 12)..<msg.index(msg.startIndex, offsetBy: 13)], as: UTF8.self) + "." + String(decoding: msg[msg.index(msg.startIndex, offsetBy: 13)..<msg.index(msg.startIndex, offsetBy: 14)], as: UTF8.self) + "." + String(decoding: msg[msg.index(msg.startIndex, offsetBy: 14)..<msg.index(msg.startIndex, offsetBy: 15)], as: UTF8.self) + "." + String(decoding: msg[msg.index(msg.startIndex, offsetBy: 15)..<msg.index(msg.startIndex, offsetBy: 16)], as: UTF8.self)

            voltage = voltageMap[Int(msg[16])] + " (V)"
            
            maxCurrent = String(msg[17]) + " (A)"
    }
}

/******** BASIC MESSAGE ********/
class BasicMessage
{
    let speedMeterModelMap = ["External, Wheel Sensor", "Internal, Motor Meter", "By Motor Phase"]
    let wheelDiameterMap = ["16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "700C", "28", "29", "30"]
    
    @Published var lowBatteryProtect: UInt8 = 18
    @Published var limitedCurrent: UInt8 = 100
    @Published var limitCurrentLevels: [UInt8] = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    @Published var limitSpeedLevels: [UInt8] = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    @Published var wheelDiameterIndex: Int = 0
    @Published var speedMeterModelIndex: Int = 0
    @Published var speedMeterSignal: UInt8 = 0
        
    init(){
        
    }
    
    init(msg: [UInt8])
    {
        lowBatteryProtect = msg[2]
        
        limitedCurrent = msg[3]

        limitCurrentLevels = [UInt8](msg[msg.index(msg.startIndex, offsetBy: 4)..<msg.index(msg.startIndex, offsetBy: 14)])
        
        limitSpeedLevels = [UInt8](msg[msg.index(msg.startIndex, offsetBy: 14)..<msg.index(msg.startIndex, offsetBy: 24)])
        
        // Convert wheel size
        let wheelDiameter = Int(msg[msg.index(msg.startIndex, offsetBy: 24)])
        let t = wheelDiameter % 2;
        let m = wheelDiameter % 2 + wheelDiameter / 2;
        if (m > 27) {
            if (m == 28) && (t == 1) { wheelDiameterIndex = 12 }
            else{ wheelDiameterIndex = m - 15 }
        }
        else { wheelDiameterIndex = m - 16 }

        // Convert speed meter type and signals
        speedMeterModelIndex = Int(msg[msg.index(msg.startIndex, offsetBy: 25)] >> 6)
        if(speedMeterModelIndex == 3) {speedMeterModelIndex = 2}
        speedMeterSignal = msg[msg.index(msg.startIndex, offsetBy: 25)] % 64
    }
    
    func toCmd() -> [UInt8] {
        var byteSendData: [UInt8] = []
        
        byteSendData.append(0x16) // Write command
        byteSendData.append(0x52) // Write location - Basic block
        byteSendData.append(24)  // 24 bytes of settings to be written to flash
        
        // Add Basic block settings
        byteSendData.append(lowBatteryProtect);
        byteSendData.append(limitedCurrent);
        byteSendData.append(contentsOf: limitCurrentLevels);
        byteSendData.append(contentsOf: limitSpeedLevels);


        if(wheelDiameterIndex == 12) { byteSendData.append(55)}// if wheel size is 700C
        else{byteSendData.append(2*UInt8(wheelDiameterMap[wheelDiameterIndex])!)}

        if(speedMeterModelIndex == 2) { byteSendData.append(3 * 64 + speedMeterSignal)} // if speed meter is by motor phase (for hub motors)
        else { byteSendData.append(UInt8(speedMeterModelIndex * 64) + speedMeterSignal)}
        // End Add Basic block settings

        let sum = byteSendData.map{Int($0)}.reduce(0, +) - Int(byteSendData[0])
        let checksum = sum % 256 // Data verification byte - equals the remainder of sum of all data bytes divided by 256
        byteSendData.append(UInt8(checksum))
        
        return byteSendData
    }
    
    func readError(err: [UInt8]) -> String{
        switch err[1] {
            case 0: //Low Battery Protect
                return "Basic Message Error - Low Battery Protection out of range, please reset!"
            case 1: //Current Limit
                return "Basic Message Error - Current Limit out of range, please reset!"
            case 2: //Current Limit 0
                return "Basic Message Error - Current Limit for PAS0 out of range, please reset!"
            case 4: //Current Limit 1
                return "Basic Message Error - Current Limit for PAS1 out of range, please reset!"
            case 6: //Current Limit 2
                return "Basic Message Error - Current Limit for PAS2 out of range, please reset!"
            case 8: //Current Limit 3
                return "Basic Message Error - Current Limit for PAS3 out of range, please reset!"
            case 10: //Current Limit 4
                return "Basic Message Error - Current Limit for PAS4 out of range, please reset!"
            case 12: //Current Limit 5
                 return "Basic Message Error - Current Limit for PAS5 out of range, please reset!"
            case 14: //Current Limit 6
                 return "Basic Message Error - Current Limit for PAS6 out of range, please reset!"
            case 16: //Current Limit 7
                 return "Basic Message Error - Current Limit for PAS7 out of range, please reset!"
            case 18: //Current Limit 8
                 return "Basic Message Error - Current Limit for PAS8 out of range, please reset!"
            case 20: //Current Limit 9
                 return "Basic Message Error - Current Limit for PAS9 out of range, please reset!"
            case 3: //Limit SPD0
                return "Basic Message Error - Speed Limit for PAS0 out of range, please reset!"
            case 5: //Limit SPD1
                return "Basic Message Error - Speed Limit for PAS1 out of range, please reset!"
            case 7: //Limit SPD2
                return "Basic Message Error - Speed Limit for PAS2 out of range, please reset!"
            case 9: //Limit SPD3
                return "Basic Message Error - Speed Limit for PAS3 out of range, please reset!"
            case 11: //Limit SPD4
                 return "Basic Message Error - Speed Limit for PAS4 out of range, please reset!"
            case 13: //Limit SPD5
                 return "Basic Message Error - Speed Limit for PAS5 out of range, please reset!"
            case 15: //Limit SPD6
                 return "Basic Message Error - Speed Limit for PAS6 out of range, please reset!"
            case 17: //Limit SPD7
                 return "Basic Message Error - Speed Limit for PAS7 out of range, please reset!"
            case 19: //Limit SPD8
                 return "Basic Message Error - Speed Limit for PAS8 out of range, please reset!"
            case 21: //Limit SPD9
                 return "Basic Message Error - Speed Limit for PAS9 out of range, please reset!"
            case 22: //Wheel Diameter
                 return "Basic Message Error - Wheel Diameter out of range, plese reset!"
            case 23: //SpdMeter Signal
                 return "Basic Message Error - Speed Meter Signals out of range, please reset!"
            case 24: // No Error
                 return ""
            default:
                return "Basic Message Error - Unknown Error n°" + String(err[1])
        }
    }
}

/******** PEDAL MESSAGE ********/
class PedalMessage
{
    let pedalTypeModeMap = ["None", "DH-SENSOR-12", "BB-SENSOR-32", "DoubleSignal-24"]
    let designatedAssistMap = ["By Display's Command"] + (0...9).map({String($0)})
    let speedLimitMap = ["By Display's Command"] + (15...40).map({String($0) + " km/h"})
    let slowStartModeMap = (1...8).map({String($0)})
    let workModeMap = ["Undeterminated"] + (10...80).map({String($0)})
    
    @Published var pedalTypeIndex: Int = 3
    @Published var designatedAssistIndex: Int = 0
    @Published var speedLimitIndex: Int = 0
    @Published var startCurrent: UInt8 = 20
    @Published var slowStartModeIndex: Int = 5
    @Published var startupDegree: UInt8 = 20
    @Published var workModeIndex: Int = 10
    @Published var stopDelay: UInt8 = 25
    @Published var currentDecay: UInt8 = 8
    @Published var stopDecay: UInt8 = 20
    @Published var keepCurrent: UInt8 = 20

    init(){
        
    }
    
    init(msg: [UInt8])
    {
        pedalTypeIndex = Int(msg[2])
        
        let designatedAssist = Int(msg[3])
        if(designatedAssist == 255) {designatedAssistIndex = 0}
        else{ designatedAssistIndex = designatedAssist + 1 }
        
        let speedLimit = Int(msg[4])
        if(speedLimit == 255) {speedLimitIndex = 0}
        else{speedLimitIndex = speedLimit - 14};
        
        startCurrent = msg[5]
        slowStartModeIndex = Int(msg[6] - 1)
        startupDegree = msg[7]
        
        let workMode = Int(msg[8])
        if(workMode == 255) {workModeIndex = 0}
        else{workModeIndex = workMode - 9};
        
        stopDelay = msg[9]
        currentDecay = msg[10]
        stopDecay = msg[11]
        keepCurrent = msg[12]
    }
    
    func toCmd() -> [UInt8] {
        var byteSendData: [UInt8] = []
        
        byteSendData.append(0x16) // Write command
        byteSendData.append(0x53) // Write location - PAS block
        byteSendData.append(11)  // 11 bytes of settings to be written to flash
        
        // Add PAS block settings
        byteSendData.append(UInt8(pedalTypeIndex))

        if(designatedAssistIndex == 0) {byteSendData.append(255)} // if PAS designated assist is set by LCD
        else {byteSendData.append(UInt8(designatedAssistIndex) - 1)}

        if(speedLimitIndex == 0) {byteSendData.append(255)} // if PAS speed limit is set by LCD
        else {byteSendData.append(UInt8(speedLimitIndex) + 14)}

        byteSendData.append(startCurrent)
        byteSendData.append(UInt8(slowStartModeIndex) + 1)
        byteSendData.append(startupDegree)

        if(workModeIndex == 0) {byteSendData.append(255)} // if PAS speed limit is set by LCD
        else {byteSendData.append(UInt8(workModeIndex) + 9)}

        byteSendData.append(stopDelay)
        byteSendData.append(currentDecay)
        byteSendData.append(stopDecay)
        byteSendData.append(keepCurrent)
        // End Add PAS block settings

        let sum = byteSendData.map{Int($0)}.reduce(0, +) - Int(byteSendData[0])
        let checksum = sum % 256 // Data verification byte - equals the remainder of sum of all data bytes divided by 256
        byteSendData.append(UInt8(checksum))
        
        return byteSendData
    }
            
    func readError(err: [UInt8]) -> String{
        switch err[1] {
            case 0: //Pedal Sensor Type
                return "Pedal Message Error - Pedal Sensor Type error, please reset!"
            case 1: //Designated Assist Level
                return "Pedal Message Error - Designated Assist Level error, please reset!"
            case 2: //Speed Limit
                return "Pedal Message Error - Speed Limit error, please reset!"
            case 3: //Start Current
                return "Pedal Message Error - Start Current out of range, please reset!"
            case 4: //Slow-start Mode
                return "Pedal Message Error - Slow-start Mode error, please reset!"
            case 5: //Start Degree
                return "Pedal Message Error - Start Degree out of range, please reset!"
            case 6: //Work Mode
                return "Pedal Message Error - Work Mode error, please reset!"
            case 7: //Stop Delay
                return "Pedal Message Error - Stop Delay out of range, please reset!"
            case 8: //Current Decay
                 return "Pedal Message Error - Current Decay out of range, please reset!"
            case 9: //Stop Decay
                 return "Pedal Message Error - Stop Decay out of range, please reset!"
            case 10: //Keep Current
                 return "Pedal Message Error - Keep Current out of range, please reset!"
            case 11: // No Error
                return ""
            default:
                return "Pedal Message Error - Unknown Error n°" + String(err[1])
        }
    }
}

/******** THROTTLE MESSAGE ********/
class ThrottleMessage
{
    let modeMap = ["Speed", "Current"]
    let designatedAssistMap = ["By Display's Command"] + (0...9).map({String($0)})
    let speedLimitMap = ["By Display's Command"] + (15...40).map({String($0) + " km/h"})

    @Published var startVoltage: UInt8 = 11
    @Published var endVoltage: UInt8 = 35
    @Published var modeIndex: Int = 0
    @Published var designatedAssistIndex: Int = 4
    @Published var speedLimitIndex: Int = 3
    @Published var startCurrent: UInt8 = 20

    init(){
        
    }
    
    init(msg: [UInt8])
    {
        startVoltage = msg[2]
        endVoltage = msg[3]
        modeIndex = Int(msg[4])
        
        let designatedAssist = Int(msg[3])
        if(designatedAssist == 255) {designatedAssistIndex = 0}
        else{ designatedAssistIndex = designatedAssist + 1 }

        let speedLimit = Int(msg[6])
        if(speedLimit == 255) {speedLimitIndex = 0}
        else{speedLimitIndex = speedLimit - 14};
        
        startCurrent = msg[7]
    }
    
    func toCmd() -> [UInt8] {
        var byteSendData: [UInt8] = []
        
        byteSendData.append(0x16) // Write command
        byteSendData.append(0x54) // Write location - Throttle block
        byteSendData.append(6)  // 6 bytes of settings to be written to flash
        
        // Add Throttle block settings
        byteSendData.append(startVoltage)
        byteSendData.append(endVoltage)
        byteSendData.append(UInt8(modeIndex))

        if(designatedAssistIndex == 0) {byteSendData.append(255)} // if Throttle assist level is set by LCD
        else {byteSendData.append(UInt8(designatedAssistIndex) - 1)}

        if(speedLimitIndex == 0) {byteSendData.append(255)} // if Throttle speed limit is set by LCD
        else {byteSendData.append(UInt8(speedLimitIndex) + 14)}

        byteSendData.append(startCurrent)

        let sum = byteSendData.map{Int($0)}.reduce(0, +) - Int(byteSendData[0])
        let checksum = sum % 256 // Data verification byte - equals the remainder of sum of all data bytes divided by 256
        byteSendData.append(UInt8(checksum))
        
        return byteSendData
    }
            
    func readError(err: [UInt8]) -> String{
        switch err[1] {
            case 0: //Start Voltage
                return "Throttle Message Error - Start Voltage out of range, please reset!!"
            case 1: //End Voltage
                return "Throttle Message Error - End Voltage out of range, please reset!"
            case 2: //Mode
                return "Throttle Message Error - Mode error, please reset!"
            case 3: //Designated Assist
                return "Throttle Message Error - Designated Assist error, please reset!"
            case 4: //Speed Limit
                return "Throttle Message Error - Speed Limit error, please reset!"
            case 5: //Start Current
                return "Throttle Message Error - Start Current out of range, please reset!"
            case 6: // No Error
                return ""
            default:
                return "Pedal Message Error - Unknown Error n°" + String(err[1])
        }
    }
}

class BafangController: ObservableObject {
    @Published var connected: Bool = false
    var connect_cmd: [UInt8] = [0x11, 0x51, 0x04, 0xb0, 0x05]
    var readBasic_cmd: [UInt8] = [0x11, 0x52]
    var readPedal_cmd: [UInt8] = [0x11, 0x53]
    var readThrottle_cmd: [UInt8] = [0x11, 0x54]
    
    var serialPort: SerialPort?
    @Published var infoMessage = InfoMessage()
    @Published var basicMessage = BasicMessage()
    @Published var pedalMessage = PedalMessage()
    @Published var throttleMessage = ThrottleMessage()

    init() {
        self.connected = false
    }
    
    func readString(ofSerialPort serialPort: SerialPort, ofLength length: Int) throws -> [UInt8] {
        var remainingBytesToRead = length
        var result = [UInt8]()

        while remainingBytesToRead > 0 {
            let data = try serialPort.readData(ofLength: remainingBytesToRead)
            result.append(contentsOf: data)
            remainingBytesToRead -= data.count
        }

        return result
    }
    
    func connect(portName: String) {
        serialPort = SerialPort(path: portName)
        
        do {
            try serialPort!.openPort()
            print("Serial port \(portName) opened successfully.")

            serialPort?.setSettings(receiveRate: .baud1200,
                               transmitRate: .baud1200,
                               minimumBytesToRead: 1,
                               timeout: 1)
        
            try serialPort!.writeData(Data(connect_cmd))
            let infoMessageReceived = try readString(ofSerialPort: serialPort!, ofLength: 19)
            
            if(infoMessageReceived[0..<2] == [0x51, 0x10] && infoMessageReceived.count == 19)
            {
                infoMessage = InfoMessage(msg: infoMessageReceived)
                self.connected = true
            }

            } catch PortError.failedToOpen {
                print("Serial port \(portName) failed to open. You might need root permissions.")
            } catch {
                print("Error: \(error)")
            }
    }
    
    func readBasic()
    {
        do{
            try serialPort!.writeData(Data(readBasic_cmd))
            let basicMessageReceived = try readString(ofSerialPort: serialPort!, ofLength: 27)
            if(basicMessageReceived[0..<2] == [0x52, 0x18] && basicMessageReceived.count == 27)
            {
                basicMessage = BasicMessage(msg: basicMessageReceived)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func readPedal()
    {
        do{
            try serialPort!.writeData(Data(readPedal_cmd))
            let pedalMessageReceived = try readString(ofSerialPort: serialPort!, ofLength: 14)
            if(pedalMessageReceived[0..<2] == [0x53, 0x0b] && pedalMessageReceived.count == 14)
            {
                pedalMessage = PedalMessage(msg: pedalMessageReceived)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func readThrottle()
    {
        do{
            try serialPort!.writeData(Data(readThrottle_cmd))
            let throttleMessageReceived = try readString(ofSerialPort: serialPort!, ofLength: 9)
            if(throttleMessageReceived[0..<2] == [0x54, 0x06] && throttleMessageReceived.count == 14)
            {
                throttleMessage = ThrottleMessage(msg: throttleMessageReceived)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func writeBasic() -> String
    {
        do{
            try serialPort!.writeData(Data(basicMessage.toCmd()))
            let errorBasicMessageReceived = try readString(ofSerialPort: serialPort!, ofLength: 3)
            if(errorBasicMessageReceived[0] == 0x52 && errorBasicMessageReceived.count == 3)
            {
                return basicMessage.readError(err: errorBasicMessageReceived)
            }
        }
        catch {
            return("Error: \(error)")
        }
        return ""
    }
    
    func writePedal() -> String
    {
        do{
            try serialPort!.writeData(Data(pedalMessage.toCmd()))
            let errorPedalMessageReceived = try readString(ofSerialPort: serialPort!, ofLength: 3)
            if(errorPedalMessageReceived[0] == 0x53 && errorPedalMessageReceived.count == 3)
            {
                return pedalMessage.readError(err: errorPedalMessageReceived)
            }
        }
        catch {
            return("Error: \(error)")
        }
        return ""
    }
    
    func writeThrottle() -> String
    {
        do{
            try serialPort!.writeData(Data(throttleMessage.toCmd()))
            let errorThrottleMessageReceived = try readString(ofSerialPort: serialPort!, ofLength: 3)
            if(errorThrottleMessageReceived[0] == 0x54 && errorThrottleMessageReceived.count == 3)
            {
                return throttleMessage.readError(err: errorThrottleMessageReceived)
            }
        }
        catch {
            return("Error: \(error)")
        }
        return ""
    }
    
    func readFlash()
    {
        readBasic()
        readPedal()
        readThrottle()
    }
    
    func writeFlash() -> String
    {
        var errorMsg = writeBasic();
        
        if(errorMsg == "")
        {
            errorMsg = writePedal();
            if(errorMsg == "")
            {
                errorMsg = writeThrottle();
            }
        }
        
        return errorMsg
    }
    
    func disconnect() {
        serialPort!.closePort()
        print("Port Closed")
        
        self.connected = false
    }
}
