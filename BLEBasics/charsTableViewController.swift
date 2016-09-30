
//
//  charsTableViewController.swift
//
//
//  Created by MARION JACK RICKARD on 8/2/16. blah not blah
//  Copyright © 2016 Jack Rickard. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

class charsTableViewController: UITableViewController, CBPeripheralDelegate, UITextFieldDelegate
{
    var foundCharacteristics = [Int: CBCharacteristic]()
    // var foundCharacteristics = NSMutableOrderedSet()
    var characteristicProps = [CBUUID: UInt]()
    var characteristicPropString = [CBUUID: String]()
    var characteristicFormatString = [CBUUID: String]()
    var characteristicNumberFormat = [CBUUID: Int]()
    var characteristicNumberFormatString = [CBUUID: String]()
    var characteristicExponent = [CBUUID: Int8]()
    var characteristicUnits = [CBUUID: UInt16]()
    var characteristicUnitString = [CBUUID: String]()
    var characteristicValue = [CBUUID: Data]()
    var characteristicASCIIValue = [CBUUID: NSString]()
    var characteristicDecimalValue = [CBUUID: String]()
    var characteristicHexValue = [CBUUID: String]()
    var characteristicUserDescription = [CBUUID: String]()
    var characteristicSubscribed = [CBUUID: UInt]()
    var subString: String = "Subscribed"
    var writeString: String = ""
    var writeFlag: Bool = false
    
    @IBOutlet var characteristicsTableView: UITableView!
    
    var service: CBService!
    var peripheral: CBPeripheral!
    
    @IBOutlet var serviceUUID: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        peripheral.readRSSI()
        characteristicsTableView.dataSource = self
        characteristicsTableView.delegate = self
        characteristicsTableView.estimatedRowHeight = 474
        //characteristicsTableView.rowHeight = UITableViewAutomaticDimension
        
        print("\nSelected PeripheralUUID: \(peripheral.identifier.uuidString)")
        
        print("Selected Peripheral Name: \(peripheral.name as NSString!)")
        
        peripheral.delegate = self
        self.refreshControl?.addTarget(self, action: #selector(charsTableViewController.startScanningCharacteristics), for: .valueChanged)
        print("Selected Service: \(service.uuid.description)")
        
        startScanningCharacteristics()
        
        //serviceUUID.text = service!.UUID.description
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func startScanningCharacteristics()
    {
        print("\n...Started scanning for Characteristics...")
        // foundCharacteristics.removeAllObjects()
        
        // peripheral.discoverCharacteristics(nil, forService: (service as CBService))
        foundCharacteristics.removeAll()
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        var index:Int=0
        for characteristic in service.characteristics!
        {
            foundCharacteristics[index] = characteristic
            index += 1
            print("\nCharacteristic Index: \(index)")
            
            print("Number of Characteristics Discovered: \(foundCharacteristics.count)")
            
            print("Discovered characteristic:\(characteristic) with properties: \(characteristic.properties)")
            //print("Characteristic service: \(characteristic.service.UUID)")
            print("Characteristic UUID: \(characteristic.uuid)")
            
            characteristicProps[characteristic.uuid] = characteristic.properties.rawValue
            print("Characteristic Properties: \(characteristicProps[characteristic.uuid]!)")
            
            var prpString = ""
            
            if 0 != characteristicProps[characteristic.uuid]! & 1
            {
                prpString += "Broadcast."
            }
            if 0 != characteristicProps[characteristic.uuid]! & 2
            {
                prpString += "Read."
            }
            if 0 != characteristicProps[characteristic.uuid]! & 4
            {
                prpString +=  "Write without Response."
            }
            if 0 != characteristicProps[characteristic.uuid]! & 8
            {
                prpString +=  "Write."
            }
            if 0 != characteristicProps[characteristic.uuid]! & 16
            {
                prpString +=  "Notify."
                //peripheral.setNotifyValue(true, forCharacteristic: characteristic) //If NOTIFY, let's subscribe for updates
            }
            if 0 != characteristicProps[characteristic.uuid]! & 32
            {
                prpString +=  "Indicate."
            }
            if 0 != characteristicProps[characteristic.uuid]! & 64
            {
                prpString +=  "Authenticated Signed Writes."
            }
            if 0 != characteristicProps[characteristic.uuid]! & 128
            {
                prpString +=  "Extended Properties."
            }
            
            characteristicPropString[characteristic.uuid] = prpString
            print("Characteristic Properties String: \(characteristicPropString[characteristic.uuid]!)")
            
            tableView.reloadData()
            peripheral.discoverDescriptors(for: characteristic)
            peripheral.readValue(for: characteristic)
        }
        
        print("\n....READING CHARACTERISTIC VALUES....\n")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        if let error = error
        {
            print("Failed to update value for characteristic with error: \(error)")
        }
        else
        {
            var UpdateValue: Int = 0
            
            (characteristic.value! as NSData).getBytes(&UpdateValue, length: MemoryLayout<Int>.size) //Converts NSData object to Integer
            
            print("\nCharacteristic NSData: \(characteristic)")
            // print("Characteristic Value string: \(characteristic.value!)")
            // print("UpdateValue: \(UpdateValue)")
            var notMuch: Int = 0
            let notMuchNS = Data(bytes: UnsafePointer<UInt8>(&notMuch), count: sizeof(Int))
            
            characteristicValue[characteristic.uuid] = characteristic.value ?? notMuchNS
            print("Stored value: \(characteristicValue[characteristic.uuid]!)")
            
            if let ASCIIstr = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
            {
                characteristicASCIIValue[characteristic.uuid] = ASCIIstr
                print("Stored ASCII: \(characteristicASCIIValue[characteristic.uuid]!)")
            }
            
            characteristicHexValue[characteristic.uuid] = (String(format:"%2X",UpdateValue))
            print("Stored Hex value: \(characteristicHexValue[characteristic.uuid]!)")
            characteristicDecimalValue[characteristic.uuid] = (String(format:"%2D",UpdateValue))
            print("Stored Decimal value: \(characteristicDecimalValue[characteristic.uuid]!)")
            
            /* Interesting experiment to update just the TableView rows corresponding to the updated value
             It didn't actually work.  You need to update the entire tableview.  But interesting...
             
             let keyArray = [CBUUID](characteristicValue.keys)
             var row:Int = 0
             for (index,value)in keyArray.enumerate(){if value == characteristic.UUID {row = index-1}}
             This line above calculates an integer value of the position of our updated value to use as a ROW in Indexpath
             
             let index = NSIndexPath(forRow: row, inSection: 0)
             tableView.reloadRowsAtIndexPaths([index], withRowAnimation: UITableViewRowAnimation.None)
             With no animation, the row simply updates with no visuals indicating a change but the change in values.
             it does so at row INDEX which corresponds to the current charactersitic value position.
             */
            
            if writeFlag == false{tableView.reloadData()}
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        if characteristic.descriptors?.count != 0
        {
            print("\nDid discover DESCRIPTORS for Characteristic: \(characteristic.uuid)")
            
            for desc in characteristic.descriptors!
            {
                
                peripheral.readValue(for: desc)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor desc: CBDescriptor, error: Error?)
    {
        if let error = error
        {
            print("Failed to update value for characteristic with error: \(error)")
        }
        else
        {
            var numFormat: Int = 0
            var exponent: Int8 = 0
            var Units: UInt16 = 0
            
            print("\nDESCRIPTOR: \(desc.characteristic.uuid)....\(desc)....\(desc.uuid)...\(desc.value!)")
            
            if desc.description.range(of: "Characteristic User Description") != nil
            {
                characteristicUserDescription[desc.characteristic.uuid] = desc.value as?String
                print("Stored User Description: \(desc.characteristic.uuid) : \(characteristicUserDescription[desc.characteristic.uuid]!) ")
            }
            
            if desc.description.range(of: "Client Characteristic Configuration") != nil
            {
                characteristicSubscribed[desc.characteristic.uuid] = (desc.value! as AnyObject).uintValue
                print("Stored Client Characteristic Configuration (subscribed) : \(desc.characteristic.uuid) : \(characteristicSubscribed[desc.characteristic.uuid]!) ")
            }
            
            //SHORT FORM if let r = desc.description.rangeOfString("Characteristic Format")
            if desc.description.range(
                of: "Characteristic Format",
                options: NSString.CompareOptions.literal,
                range: desc.description.characters.indices,
                locale: nil) != nil
            {
                characteristicFormatString[desc.characteristic.uuid] = "\(desc.value!)"
                
                print("Presentation Format Descriptor:\(characteristicFormatString[desc.characteristic.uuid]!) ")
                
                (desc.value! as AnyObject).getBytes(&numFormat, range:NSMakeRange(0,1)) //Converts NSData object to Integer
                // print("Value data format: 0x\(NSString(format:"%2X",numFormat))....\(NumericType[numFormat]) ")
                characteristicNumberFormat[desc.characteristic.uuid] = numFormat
                characteristicNumberFormatString[desc.characteristic.uuid] = NumericType[numFormat]
                print("Stored Number Format: \(desc.characteristic.uuid) : \(characteristicNumberFormat[desc.characteristic.uuid]!) ")
                print("Stored Number Format String: \(desc.characteristic.uuid) : \(characteristicNumberFormatString[desc.characteristic.uuid]!) ")
                
                (desc.value! as AnyObject).getBytes(&exponent, range: NSMakeRange(1,1)) //Converts NSData object to Integer
                // print("Value Exponent: \(exponent) ")
                characteristicExponent[desc.characteristic.uuid] = exponent
                print("Stored Exponent: \(desc.characteristic.uuid) : \(characteristicExponent[desc.characteristic.uuid]!) ")
                
                (desc.value! as AnyObject).getBytes(&Units, range: NSMakeRange(2,2)) //Converts NSData object to Integer
                characteristicUnits[desc.characteristic.uuid] = Units
                characteristicUnitString[desc.characteristic.uuid] = unitDefinitions[Units ?? 0x2700]
                
                print("Stored Units: \(desc.characteristic.uuid) : 0x\(NSString(format:"%2X",characteristicUnits[desc.characteristic.uuid]!))")
                
                print("Stored Unit String: \(desc.characteristic.uuid) : \(characteristicUnitString[desc.characteristic.uuid] ?? "None")")
                
                tableView.reloadData()
            }
        }
    }
    
    override func numberOfSections(in characteristicsTableView: UITableView) -> Int
    {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ characteristicsTableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete implementation, return the number of rows
        // return characteristicValue.count
        return foundCharacteristics.count
    }
    
    override func tableView(_ characteristicsTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var UpdateValue: Int64 = 0
        let date=Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let convertedDate = dateFormatter.string(from: date)
        
        if foundCharacteristics.count > 0
        {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "charsCell", for: indexPath) as!    CharacteristicTableViewCell
            //  print("Index path and row: \(indexPath.row)")
            // print("Number of characteristics found: \(foundCharacteristics.count)")
            
            if foundCharacteristics[(indexPath as NSIndexPath).row] != nil
            {
                let Mycharacteristic = self.foundCharacteristics[(indexPath as NSIndexPath).row]!
                //    print("Characteristic UUID: \(characteristic.UUID)")
                
                cell.UUID.text = Mycharacteristic.uuid.uuidString ?? " - "
                let testString: String = "0x" + String(format:"%2X",(self.characteristicProps[Mycharacteristic.uuid] ?? 0))
                //print("Properties value retrieved: \(testString)")
                cell.rawProperties.text = testString
                
                subString = ""
                let MyProperties = characteristicProps[Mycharacteristic.uuid] ?? 0
                
                if 0 != MyProperties & 4 || 0 != MyProperties & 8
                {
                    cell.ValueEntryField.isHidden = false
                    cell.ValueEntryField.delegate = self
                    if self.characteristicValue[Mycharacteristic.uuid] != nil
                    {
                        let myString = String(describing: self.characteristicValue[Mycharacteristic.uuid]!)
                        cell.ValueEntryField.text = myString
                    }
                    
                    cell.ValueEntryField.textColor = UIColor.red
                    cell.ValueEntryField.borderStyle = UITextBorderStyle.bezel
                    cell.ValueEntryField.tag = (indexPath as NSIndexPath).row
                    cell.ValueEntryField.addTarget(self,action: #selector(charsTableViewController.newValue(_:)),for: UIControlEvents.editingDidEnd)
                }
                else { cell.ValueEntryField.isHidden = true}
                
                
                if 0 != MyProperties & 16 || 0 != MyProperties & 2 || 0 != MyProperties & 32
                {
                    cell.Unsubscribe.isHidden = false
                    cell.Unsubscribe.tag = (indexPath as NSIndexPath).row
                    cell.Unsubscribe.addTarget(self,action:#selector(charsTableViewController.unSubscribe(_:)),for: .touchUpInside)
                }
                else { cell.Unsubscribe.isHidden = true}
                
                if 0 != MyProperties & 2
                {
                    let date2=Date()
                    let dateFormatter2 = DateFormatter()
                    dateFormatter2.dateFormat = "HH:mm:ss.SSS"
                    let convertedDate2 = dateFormatter2.string(from: date2)
                    
                    subString = " - READ AT " + convertedDate2
                }
                
                if 0 != MyProperties & 16 || 0 != MyProperties & 32
                {
                    if ((self.characteristicSubscribed[Mycharacteristic.uuid] ?? 0) == 0)
                    {
                        subString = "  - UNSUBSCRIBED"
                    }
                    if ((self.characteristicSubscribed[Mycharacteristic.uuid] ?? 0) == 1 || (self.characteristicSubscribed[Mycharacteristic.uuid] ?? 0) == 2)
                    {
                        subString = "  - SUBSCRIBED updated:" + convertedDate
                    }
                }
                else if 0 != MyProperties & 2
                {
                    let date=Date()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "HH:mm:ss.SSS"
                    let convertedDate = dateFormatter.string(from: date)
                    
                    subString = " - READ AT " + convertedDate
                }
                
                cell.propertyString.text = (self.characteristicPropString[Mycharacteristic.uuid] ?? "None") + subString
                
                //print("\nCharacteristic Value string in cell: \(self.characteristicValue[Mycharacteristic.UUID] ?? "empty")")
                
                if self.characteristicValue[Mycharacteristic.uuid] != nil
                {
                    cell.rawValue.text = String(describing: self.characteristicValue[Mycharacteristic.uuid]!)
                    
                    (characteristicValue[Mycharacteristic.uuid]! as NSData).getBytes(&UpdateValue, length: MemoryLayout<Int64>.size) //Converts NSData object to Integer
                    
                    cell.hexValue.text = String(format:"%2X",UpdateValue)
                    cell.decValue.text = String(format:"%2d",UpdateValue)
                    //Let's take our decimal value and apply any exponents available
                    let UpdateValue2 = NumberFormatter().number(from: cell.decValue.text!)
                    
                    var x : Int8 = self.characteristicExponent[Mycharacteristic.uuid] ?? 0
                    
                    cell.valueExponent.text = String(format:"%2d",x)
                    
                    var exponentValue = Double(UpdateValue2!)
                    let exponentValueSimple = Int(UpdateValue2!)
                    
                    switch x
                    {
                    case 1 ... 100:
                        for _ in 1 ... x
                        {
                            exponentValue *= 10
                        }
                        
                    default:         //Exponent is either zero or negative
                        x *= -1      //Convert it to a positive
                        if x > 0
                        {
                            for _ in 1...x
                            {
                                exponentValue /= 10  //and divide instead of multiply
                            }
                        }
                    }
                    
                    if let ASCIIstr = String(data: self.characteristicValue[Mycharacteristic.uuid]!, encoding: String.Encoding.utf8)
                    {
                        cell.ASCIIvalue.text = ASCIIstr
                    }
                    else
                    {
                        cell.ASCIIvalue.text = " - "
                    }
                    
                    if (x==0)
                    {
                        cell.presentedValue.text = String(exponentValueSimple)
                    }
                    
                    if (cell.ASCIIvalue.text!.characters.count > 5)
                    {
                        cell.presentedValue.text = cell.ASCIIvalue.text
                    }
                    else
                    {
                        if (x==0) //If the exponents is zero we want to print as a simple integer
                        {
                            cell.presentedValue.text = String(exponentValueSimple)
                        }
                        else     //If exponent is non-zero, we want to print the value in decimal
                        {
                            cell.presentedValue.text = String(exponentValue)
                        }
                    }
                }
                
                cell.presentationFormat.text = self.characteristicFormatString[Mycharacteristic.uuid] ?? " None "
                
                cell.valueFormat.text = self.characteristicNumberFormatString[Mycharacteristic.uuid] ?? " None given"
                
                let MyUnitString = "0x" + String(format:"%2X",self.characteristicUnits[Mycharacteristic.uuid] ?? 0x2700)
                
                let MyUnitString2 = self.characteristicUnitString[Mycharacteristic.uuid] ?? " "
                
                cell.valueUnits.text = MyUnitString + " " + MyUnitString2
                
                cell.userDescription.text = self.characteristicUserDescription[Mycharacteristic.uuid] ?? " "
                
                let combinedString = " " + (cell.userDescription.text ?? " - ")
                
                cell.presentedValue.text = cell.presentedValue.text! + " " + (self.characteristicUnitString[Mycharacteristic.uuid] ?? " ") + combinedString
            }
            return cell
        }
        else
        {
            return UITableViewCell()
        }
    }
    
    @IBAction func unSubscribe(_ sender: UIButton)
    {
        let UNScharacteristic = self.foundCharacteristics[sender.tag]!
        let MyProperties = characteristicProps[UNScharacteristic.uuid] ?? 0
        
        if 0 != MyProperties & 16 || 0 != MyProperties & 32
        {
            let subs = (characteristicSubscribed[UNScharacteristic.uuid] ?? 0)
            if subs == 1 || subs == 2
            {
                peripheral.setNotifyValue(false, for: UNScharacteristic)
                self.characteristicSubscribed[UNScharacteristic.uuid] = 0
            }
            if subs == 0
            {
                peripheral.setNotifyValue(true, for: UNScharacteristic)
                self.characteristicSubscribed[UNScharacteristic.uuid] = 1
            }
            peripheral.discoverDescriptors(for: UNScharacteristic)
            peripheral.readValue(for: UNScharacteristic)
        }
        else if 0 != MyProperties & 2
        {
            peripheral.readValue(for: UNScharacteristic)
        }
    }
    
    @IBAction func newValue(_ sender: UITextField)
    {
        //This method picks up a string entered on the keyboard to write to a write type characterisic
        //It processes it to send as a string, a 32-bit value, or a bool
        
        let UNScharacteristic = self.foundCharacteristics[sender.tag]!
        print("Picked up writeString: \(writeString)")
        let myNSString: NSString = writeString as NSString
        print("NEW NSString: \(myNSString)")
        
        var newValue: Int32 = 0
        var dummyValue: Int8 = 1
        var anothernewValue: UInt32 = 0
        var anothernewValue64: UInt64 = 0
        let newvalScanner = Scanner (string: writeString)
        var newValueNSD: Data
        
        newValueNSD = Data(bytes: UnsafePointer<UInt8>(&newValue), count: sizeof(Int64)) //First let's set it to zero so we have SOMETHING
        
        if myNSString.contains("\"")  //If it contains text in quotes, let's send the text (without the quotes)
        {
            let wrongString = writeString.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
            let myNSString2: NSString = wrongString as NSString
            newValueNSD = myNSString2.data(using: String.Encoding.utf8.rawValue)!
        }
        else if myNSString.contains("0x") //But if it leads with 0x, let's scan for hex and send 32-bit hex value
        {
            if writeString.characters.count < 11
            {
                newvalScanner.scanHexInt32(&anothernewValue)
                newValueNSD = Data(bytes: UnsafePointer<UInt8>(&anothernewValue), count: sizeof(Int32))
            }
            else
            {
                newvalScanner.scanHexInt64(&anothernewValue64)
                newValueNSD = Data(bytes: UnsafePointer<UInt8>(&anothernewValue64), count: sizeof(Int64))
            }
        }
        else
        {
            newvalScanner.scanInt32(&newValue)// Let's scan for decimal digits and send as 32bits
            newValueNSD = Data(bytes: UnsafePointer<UInt8>(&newValue), count: sizeof(Int32))
        }
        
        if myNSString.contains("on") || myNSString.contains("ON") //If it contains "on" send an 8-bit containing 1
        {
            dummyValue = 1
            newValueNSD = Data(bytes: UnsafePointer<UInt8>(&dummyValue), count: sizeof(Int8))
        }
        
        if myNSString.contains("off") || myNSString.contains("OFF")//If it contains "off" send an 8-bit containing 0
        {
            dummyValue = 0
            newValueNSD = Data(bytes: UnsafePointer<UInt8>(&dummyValue), count: sizeof(Int8))
        }
        
        print ("After scanning we get...\(newValueNSD)")
        
        characteristicValue[UNScharacteristic.uuid] = newValueNSD
        print("New characteristic value = \(characteristicValue[UNScharacteristic.uuid]!)")
        
        peripheral.writeValue(newValueNSD, for: UNScharacteristic, type: CBCharacteristicWriteType.withResponse)
        
        writeFlag = false //resume characteristic updates for notifies
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    {
        //After writing out new value to a characteristic, this delegate will catch returned errors or responses.
        //It's nothing we need, but it is important to have a delegate to catch them so they don't just show up with
        //nowhere to go.
        
        if let error = error
        {
            print("Failed to write data to characteristic with error: \(error)")
        }
        else
        {
            print("Apparently our write data to characteristic was successful...: \(error)")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        //We have pressed DONE on keyboard.  This picks up our entered string and stores it in a global variable, then removes
        //keyboard from screen
        
        writeString = textField.text!
        print("We created writeString: \(writeString)")
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        
        writeFlag = true  //When we bring up the keyboard, we use this to stop NOTIFIES from updating
        //our tableview while we are trying to enter data
        return true
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    /*   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
     
     {
     let Mycharacteristic = self.foundCharacteristics[characteristicsTableView.indexPathForSelectedRow!.row]!
     print(".............S..E..G..U..E............")
     peripheral.setNotifyValue(false, forCharacteristic: Mycharacteristic)
     }*/
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?)
    {
        //print("Did read RSSI.")
        if let error = error
        {
            print("Error getting RSSI: \(error)")
            //RSSILabel.text = "Error getting RSSI."
        }
        else
        {
            print("RSSI: \(RSSI.intValue)")
            // RSSILabel.text = "\(RSSI.integerValue)"
        }
    }
    
} //end of charsTableViewController class
