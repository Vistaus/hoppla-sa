/*
 *    Copyright 2016-2017 Christian Loosli <develop@fuchsnet.ch>
 * 
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) version 3, or any
 *    later version accepted by the original Author.
 * 
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 * 
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.2
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kcoreaddons 1.0 as KCoreAddons
import "../code/hue.js" as Hue


Item {
    width: parent.width
    anchors.left: parent.left
    anchors.right: parent.right
    
    ListModel {
        id: groupsModel
    }
    
    ListModel {
        id: cbClassModel
    }
    
    ListModel {
        id: groupLightsModel
    }
    
    ListModel {
        id: availableLightsModel
    }
    
    Component.onCompleted: {
        if(!Hue.isInitialized()) {
            Hue.initHueConfig();
        }
        groupsModel.clear();
        getGroups();
        Hue.fillWithClasses(cbClassModel);
    }
    
    function rbTypeChanged() {
        if(rbRoom.checked) {
            availableLightsModel.clear();
            Hue.getAvailableLightsIdName(availableLightsModel);
        }
        else if(rbGroup.checked) {
            availableLightsModel.clear();
            Hue.getLightsIdName(availableLightsModel);
        }
    }
    
    function getGroups() {
        groupsModel.clear()
        Hue.getGroupsIdName(groupsModel);
    }
    
    function resetDialog() {
        groupLightsModel.clear();
        txtGroupName.text = ""
        rbGroup.checked = true; 
        rbRoom.checked = false;
        cbClass.currentIndex = 0;
        rbTypeChanged();
    }
    
    function addLight(lightId, lightName) {
        groupLightsModel.append( { vuuid: lightId, vname: lightName });
    }
    
    function getLightsForGroup(groupId, slights) {
        groupLightsModel.clear();
        Hue.getGroupLights(groupLightsModel, slights);
    }
    
    function addGroup() {
        resetDialog();
        editGroupDialogue.groupId = "-1";
        editGroupDialogue.open();
    }
    
    function groupListChanged() {
        
    }
    
    ColumnLayout {
        Layout.fillWidth: true
        anchors.left: parent.left
        anchors.right: parent.right
        
        TableView {
            id: groupsTable
            width: parent.width
            
            TableViewColumn {
                id: idCol
                role: 'uuid'
                title: i18n('ID')
                width: parent.width * 0.08
                
                delegate: Label {
                    text: styleData.value
                    elide: Text.ElideRight
                }
            }
            
            TableViewColumn {
                id: nameCol
                role: 'name'
                title: i18n('Name')
                width: parent.width * 0.72
                
                delegate: Label {
                    text: styleData.value
                    elide: Text.ElideRight
                }
            }
            
            TableViewColumn {
                title: i18n('Action')
                width: parent.width * 0.12
                
                delegate: Item {
                    
                    GridLayout {
                        height: parent.height
                        columns: 2
                        rowSpacing: 0
                        
                        
                        Button {
                            iconName: 'entry-edit'
                            Layout.fillHeight: true
                            onClicked: {
                                resetDialog();
                                var editItem = groupsModel.get(styleData.row);
                                txtGroupName.text = editItem.name;
                                editGroupDialogue.groupId = editItem.uuid;
                                if( editItem.type == "Room" ) {
                                    rbRoom.checked = true;
                                    cbClass.currentIndex = cbClass.find(editItem.tclass);
                                }
                                else if (editItem.type == "Group" ) {
                                    rbGroup.checked = true;
                                }
                                else { 
                                    // can't manage that type, should not happen
                                    return;
                                }
                                getLightsForGroup(editItem.uuid, editItem.slights);
                                rbTypeChanged();

                                editGroupDialogue.open();
                            }
                        }
                        
                        
                        Button {
                            iconName: 'list-remove'
                            Layout.fillHeight: true
                            onClicked: {
                                // groupsModel.remove(styleData.row)
                                // groupListChanged()
                            }
                        }
                    }
                }
            }
            model: groupsModel
            Layout.preferredHeight: 290
            Layout.preferredWidth: parent.width
            Layout.columnSpan: 2
        }
        
        Button {
            id: btnAddGroup
            text: i18n("Add new group")
            onClicked: addGroup()
        }
        
        Dialog {
            id: editGroupDialogue
            title: i18n('Create or edit group')
            width: 500
            
            property string groupId: ""
            
            standardButtons: StandardButton.Ok | StandardButton.Cancel
            
            onAccepted: {
                // TODO: Sanity check, jsonify, save all
                close()
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                anchors.left: parent.left
                anchors.right: parent.right
                
                GridLayout {
                    id: grdTitle
                    anchors.left: parent.left
                    anchors.right: parent.right
                    columns: 3
                    Layout.fillWidth: true
                    
                    Label {
                        Layout.alignment: Qt.AlignRight
                        text: i18n("Group name:")
                    }
                    
                    TextField {
                        Layout.columnSpan: 2
                        id: txtGroupName
                        Layout.fillWidth: true
                        maximumLength: 32
                    }
                    
                    Label {
                        Layout.alignment: Qt.AlignRight
                        text: i18n("Group type:")
                    }
                    
                    ExclusiveGroup { id: typeGroup }
                    
                    RadioButton {
                        id: rbGroup
                        text: i18n("Group")
                        checked: true
                        exclusiveGroup: typeGroup
                        onClicked: { 
                            rbTypeChanged()
                        }
                    }
                    RadioButton {
                        id: rbRoom
                        text: i18n("Room")
                        exclusiveGroup: typeGroup
                        onClicked: { 
                            rbTypeChanged()
                        }
                    }
                    
                    Label {
                    }
                    
                    Label {
                        Layout.columnSpan: 2
                        font.italic: true
                        text: i18n("A light can only be in one room but multiple groups at the same time.")
                    }
                    
                    Label {
                    }
                    
                    Label {
                        Layout.columnSpan: 2
                        font.italic: true
                        text: i18n("Only rooms have a class with a specific icon, groups only have a name")
                    }
                    
                    Label {
                        Layout.alignment: Qt.AlignRight
                        text: i18n("Class")
                    }
                    
                    ComboBox {
                        id: cbClass
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        model: cbClassModel
                        enabled: rbRoom.checked
                        textRole: 'translatedName'
                    }
                }
                
                GroupBox {
                    Layout.fillWidth: true
                    id: grpNewLight
                    title: i18n("Lights");
                    
                    GridLayout {
                        id: grdLight
                        anchors.left: parent.left
                        anchors.right: parent.right
                        columns: 3
                        Layout.fillWidth: true
                        
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: i18n("light: ")
                        }
                        
                        ComboBox {
                            id: cbLight
                            model: availableLightsModel
                            Layout.fillWidth: true
                            textRole: 'name'
                            
                        }
                        
                        Button {
                            id: btnAddLight
                            text: i18n("Add light");
                            onClicked: {
                                var cLight = availableLightsModel.get(cbLight.currentIndex);
                                if(cLight && cLight.uuid != "-1") {
                                    addLight(cLight.uuid, cLight.name)
                                }
                            }
                        }
                        
                        TableView {
                            id: lightTable
                            width: parent.width
                            
                            TableViewColumn {
                                id: lightIdCol
                                role: 'vuuid'
                                title: i18n('Id')
                                width: parent.width * 0.1
                                
                                delegate: Label {
                                    text: styleData.value
                                }
                            }
                            
                            TableViewColumn {
                                id: lightNameCol
                                role: 'vname'
                                title: i18n('Name')
                                width: parent.width * 0.72
                                
                                delegate: Label {
                                    text: styleData.value
                                    elide: Text.ElideRight
                                }
                            }
                            
                            TableViewColumn {
                                title: i18n('Remove')
                                width: parent.width * 0.15
                                
                                delegate: Item {
                                    
                                    GridLayout {
                                        height: parent.height
                                        columns: 1
                                        rowSpacing: 0
                                        
                                        Button {
                                            iconName: 'list-remove'
                                            Layout.fillHeight: true
                                            onClicked: {
                                                groupLightsModel.remove(styleData.row)
                                            }
                                        }
                                    }
                                }
                            }
                            model: groupLightsModel
                            Layout.preferredHeight: 110
                            Layout.preferredWidth: parent.width
                            Layout.columnSpan: 3
                        }
                    }
                }
            }
        }
    }
}
