//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Issac Penn on 2019/12/15.
//  Copyright © 2019 Issac Penn. All rights reserved.
//

import SwiftUI
import CodeScanner
import UserNotifications

struct ProspectsView: View {
    @EnvironmentObject var prospects: Prospects
    @State private var isShowingScanner = false
    @State private var sorting: Sorting = .recent
    @State private var isShowingSortingAction = false

    let filter: FilterType
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter({ $0.isContacted })
        case .uncontacted:
            return prospects.people.filter({ !$0.isContacted })
        }
    }
    
    var sortedProspects: [Prospect] {
        switch sorting {
        case .recent:
            return filteredProspects.reversed()
        case .name:
            return filteredProspects.sorted(by: { $0.name < $1.name })
        }
    }
    
    var body: some View {
        NavigationView {
            List{
                ForEach(sortedProspects) { prospect in
                    HStack {
                        if self.filter == .none {
                            if prospect.isContacted {
                                Image(systemName: "checkmark.circle")
                            } else {
                                Image(systemName: "questionmark.diamond")
                            }
                        }
                        VStack (alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        .contextMenu {
                            Button(prospect.isContacted ? "Mark Uncontacted" : "Mark Contacted") {
                                self.prospects.toggle(prospect)
                            }
                            if !prospect.isContacted {
                                Button("Remind Me") {
                                    self.addNotification(for: prospect)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(title)
            .navigationBarItems(
                leading: Button(action: {
                    self.isShowingSortingAction = true
                }) {
                    Image(systemName: "arrow.up.arrow.down.square")
                    Text("Sort")
                },
                trailing: Button(action: {
                    self.isShowingScanner = true
                }) {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
            })
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: self.handleScan(result:))
            }
            .actionSheet(isPresented: $isShowingSortingAction) {
                ActionSheet(title: Text("Sort by"), message: nil, buttons: [
                    .default(Text("Name"), action: { self.sorting = .name }),
                    .default(Text("Recent"), action: { self.sorting = .recent }),
                    .cancel()
                ])
            }
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        
        switch result {
        case .success(let code):
            let details = code.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            
            self.prospects.add(person)

        case .failure(let error):
            print("Scanning failed, error: \(error)")
        }
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
            var dateComponents = DateComponents()
            dateComponents.hour = 9
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            center.add(request)
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh")
                    }
                }
            }
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
    }
}

extension ProspectsView {
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    enum Sorting {
        case name, recent
    }
}
