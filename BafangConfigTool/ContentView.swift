//
//  ContentView.swift
//  BafangConfigTool
//
//  Created by Clément Le Bihan on 02/06/2020.
//  Copyright © 2020 Clément Le Bihan. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    let bafangController = BafangController()

    var body: some View {
        VStack {
            HStack {
                TabView(selection: /*@START_MENU_TOKEN@*/ /*@PLACEHOLDER=Selection@*/.constant(1)/*@END_MENU_TOKEN@*/) {
                    List {
                        DisplayBasicMessageView().environmentObject(bafangController)
                    }.tabItem { Text("Basic") }.tag(1)
                    List {
                        DisplayPedalMessageView().environmentObject(bafangController)
                    }.tabItem { Text("Pedal Assist") }.tag(2)
                    List
                    {
                        DisplayThrottleMessageView().environmentObject(bafangController)
                    }.tabItem { Text("Throttle Handle") }.tag(3)
                }.padding(.all, 15.0).frame(width: 500.0, height: 560.0)
                
                VStack(alignment: .center){
                    
                    DisplayCommInterfaceView().environmentObject(bafangController)
                    
                    DisplayInfoMessageView().environmentObject(bafangController)
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct DisplayInfoMessageView: View {
    @EnvironmentObject var bafangController: BafangController

    var body: some View {
        GroupBox(label: Text("Controller Info")) {
            VStack(alignment: .leading, spacing: 5.0){
                Text("Manufacturer : \(bafangController.infoMessage.manufacturer)")
                Text("Model : \(bafangController.infoMessage.model)")
                Text("Hardware Version : \(bafangController.infoMessage.HWVersion)")
                Text("Firmware Version : \(bafangController.infoMessage.FWVersion)")
                Text("Nominal Voltage : \(bafangController.infoMessage.voltage)")
                Text("Max Current Voltage : \(bafangController.infoMessage.maxCurrent)")
            }.padding().frame(width: 280)
        }
        .frame(width: 300.0)
    }
}

struct DisplayBasicMessageView: View {
    @EnvironmentObject var bafangController: BafangController

    var body: some View {
        Group{
            Stepper("Low Battery Protection : \(bafangController.basicMessage.lowBatteryProtect) [V]", value: $bafangController.basicMessage.lowBatteryProtect, in: 0...50, step: 1)
            Stepper("Current Limit : \(bafangController.basicMessage.limitedCurrent) [A]", value: $bafangController.basicMessage.limitedCurrent, in: 0...50, step: 1)
            
            HStack(alignment: .center, spacing: 50.0) {
                VStack(spacing: 15.0)
                {
                    Text("Assist Levels").fontWeight(.bold)
                    ForEach((0...bafangController.basicMessage.limitCurrentLevels.count-1), id: \.self) {
                        Text("Assist \($0) :")
                    }
                }
                VStack(alignment: .trailing, spacing: 9.0)
                {
                    Text("Current Limit [%]").fontWeight(.bold)
                    ForEach((0...bafangController.basicMessage.limitCurrentLevels.count-1), id: \.self) {
                        Stepper("\(self.bafangController.basicMessage.limitCurrentLevels[$0])", value: self.$bafangController.basicMessage.limitCurrentLevels[$0], in: 0...100, step: 1)
                    }
                }
                VStack(alignment: .trailing, spacing: 9.0)
                {
                    Text("Speed Limit [%]").fontWeight(.bold)
                    ForEach((0...bafangController.basicMessage.limitSpeedLevels.count-1), id: \.self) {
                        Stepper("\(self.bafangController.basicMessage.limitSpeedLevels[$0])", value: self.$bafangController.basicMessage.limitSpeedLevels[$0], in: 0...100, step: 1)
                    }
                }
                
            }.frame(width: 450.0)
            
            Picker(selection: self.$bafangController.basicMessage.speedMeterModelIndex, label: Text("Speed Meter Type :")) {
                ForEach((0...bafangController.basicMessage.speedMeterModelMap.count-1), id: \.self) {
                    Text(self.bafangController.basicMessage.speedMeterModelMap[$0]).tag($0+1)
                }
            }.frame(width: 300.0)
            
            HStack{
                Stepper("Speed Meter Signals : \(bafangController.basicMessage.speedMeterSignal) [V]", value: $bafangController.basicMessage.speedMeterSignal, in: 1...36, step: 1)
            }
            
            Picker(selection: self.$bafangController.basicMessage.wheelDiameterIndex, label: Text("Wheel Diameter [Inch] :")) {
                    ForEach((0...bafangController.basicMessage.wheelDiameterMap.count-1), id: \.self) {
                        Text(self.bafangController.basicMessage.wheelDiameterMap[$0]).tag($0+1)
                    }
            }.frame(width: 300.0)
        }
    }
}


struct DisplayPedalMessageView: View {
    @EnvironmentObject var bafangController: BafangController

    var body: some View {
        VStack(alignment: .leading){
            Group{
                Picker(selection: self.$bafangController.pedalMessage.pedalTypeIndex, label: Text("Pedal Sensor Type :")) {
                    ForEach((0...bafangController.pedalMessage.pedalTypeModeMap.count-1), id: \.self) {
                        Text(self.bafangController.pedalMessage.pedalTypeModeMap[$0]).tag($0+1)
                    }
                }.frame(width: 300.0)
                Picker(selection: self.$bafangController.pedalMessage.designatedAssistIndex, label: Text("Designated Assist Level :")) {
                    ForEach((0...bafangController.pedalMessage.designatedAssistMap.count-1), id: \.self) {
                        Text(self.bafangController.pedalMessage.designatedAssistMap[$0]).tag($0+1)
                    }
                }.frame(width: 300.0)
                Picker(selection: self.$bafangController.pedalMessage.speedLimitIndex, label: Text("Speed Limit :")) {
                    ForEach((0...bafangController.pedalMessage.speedLimitMap.count-1), id: \.self) {
                        Text(self.bafangController.pedalMessage.speedLimitMap[$0]).tag($0+1)
                    }
                }.frame(width: 300.0)
                Stepper("Start Current : \(bafangController.pedalMessage.startCurrent) [%]", value: $bafangController.pedalMessage.startCurrent, in: 0...100, step: 1)
                Picker(selection: self.$bafangController.pedalMessage.slowStartModeIndex, label: Text("Slow-start Mode :")) {
                    ForEach((0...bafangController.pedalMessage.slowStartModeMap.count-1), id: \.self) {
                        Text(self.bafangController.pedalMessage.slowStartModeMap[$0]).tag($0+1)
                    }
                }.frame(width: 300.0)
                Stepper("Start Degree (Signal N°) : \(bafangController.pedalMessage.startupDegree) [%]", value: $bafangController.pedalMessage.startupDegree, in: 0...100, step: 1)
                Picker(selection: self.$bafangController.pedalMessage.workModeIndex, label: Text("Work Mode (Angular Pedal Speed/wheel*10) :")) {
                    ForEach((0...bafangController.pedalMessage.workModeMap.count-1), id: \.self) {
                        Text(self.bafangController.pedalMessage.workModeMap[$0]).tag($0+1)
                    }
                }.frame(width: 300.0)
            }
            Group{
                Stepper("Stop Delay : \(bafangController.pedalMessage.stopDelay) [x10ms]", value: $bafangController.pedalMessage.stopDelay, in: 0...255, step: 1)
                Stepper("Current Decay : \(bafangController.pedalMessage.currentDecay)", value: $bafangController.pedalMessage.currentDecay, in: 1...8, step: 1)
                Stepper("Stop Decay : \(bafangController.pedalMessage.stopDecay) [x10ms]", value: $bafangController.pedalMessage.stopDecay, in: 0...255, step: 1)
                Stepper("Keep Current : \(bafangController.pedalMessage.keepCurrent) [%]", value: $bafangController.pedalMessage.keepCurrent, in: 0...100, step: 1)
            }
        }
    }
}

struct DisplayThrottleMessageView: View {
    @EnvironmentObject var bafangController: BafangController

    var body: some View {
        Group{
            Stepper("Start Voltage : \(bafangController.throttleMessage.startVoltage) [x100mV]", value: $bafangController.throttleMessage.startVoltage, in: 0...100, step: 1)
            Stepper("End Voltage : \(bafangController.throttleMessage.endVoltage) [x100mV]", value: $bafangController.throttleMessage.endVoltage, in: 0...100, step: 1)
            Picker(selection: self.$bafangController.throttleMessage.modeIndex, label: Text("Mode")) {
                ForEach((0...bafangController.throttleMessage.modeMap.count-1), id: \.self) {
                    Text(self.bafangController.throttleMessage.modeMap[$0]).tag($0+1)
                }
            }.frame(width: 300.0)
            Picker(selection: self.$bafangController.throttleMessage.designatedAssistIndex, label: Text("Designated Assist Level :")) {
                ForEach((0...bafangController.throttleMessage.designatedAssistMap.count-1), id: \.self) {
                    Text(self.bafangController.throttleMessage.designatedAssistMap[$0]).tag($0+1)
                }
            }.frame(width: 300.0)
            Picker(selection: self.$bafangController.throttleMessage.speedLimitIndex, label: Text("Speed Limit :")) {
                ForEach((0...bafangController.throttleMessage.speedLimitMap.count-1), id: \.self) {
                    Text(self.bafangController.throttleMessage.speedLimitMap[$0]).tag($0+1)
                }
            }.frame(width: 300.0)
            Stepper("Start Current : \(bafangController.throttleMessage.startCurrent) [%]", value: $bafangController.throttleMessage.startCurrent, in: 0...100, step: 1)

        }
    }
}


struct DisplayCommInterfaceView: View {
    @EnvironmentObject var bafangController: BafangController
    @State private var showingAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        GroupBox(label: Text("Communication Interface")) {
            VStack{
                HStack{
                    Picker(selection: /*@START_MENU_TOKEN@*/.constant(1)/*@END_MENU_TOKEN@*/, label: Text("COM Port")) {
                    Text("/dev/cu.usbserial-1420").tag(1)
                    }
                }
                HStack{
                    Button(action: {
                        self.bafangController.connect(portName: "/dev/cu.usbserial-1420")
                    }) {
                        Text("Connect")
                    }.alert(isPresented: $showingAlert) {
                        Alert(title: Text("Important message"), message: Text("Wear sunscreen"), dismissButton: .default(Text("Got it!")))
                    }.disabled(bafangController.connected)
                    Button(action: {self.bafangController.disconnect()}) {
                        Text("Disconnect")
                    }.disabled(!bafangController.connected)
                }
                HStack{
                    Button(action: {self.bafangController.readFlash()}) {
                        Text("Read Flash")
                    }.disabled(!bafangController.connected)
                    Button(action: {
                        self.errorMessage = self.bafangController.writeFlash()
                        if(self.errorMessage != "") { self.showingAlert = true}
                    }) {
                        Text("Write Flash")
                    }.alert(isPresented: $showingAlert){Alert(title: Text("Failed to write flash"), message: Text(errorMessage), dismissButton: .default(Text("Got it!")))}.disabled(!bafangController.connected)
                }
            }
        }.padding(.all, 15.0)
    }
}
