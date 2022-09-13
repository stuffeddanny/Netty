//
//  ForgotPasswordViewModel.swift
//  Netty
//
//  Created by Danny on 9/13/22.
//

import SwiftUI
import CloudKit
import Combine


class ForgotPasswordViewModel: ObservableObject {
    
    private let showAlertOnLogInScreen: (_ title: String, _ message: String) -> ()
    
    @Binding var path: NavigationPath
    
    init(path: Binding<NavigationPath>, showAlertOnLogInScreen: @escaping (String, String) -> ()) {
        self._path = path
        self.showAlertOnLogInScreen = showAlertOnLogInScreen
        addSubscribers()
    }
            
    enum EmailButtonText: String {
        case send = "Send code"
        case again = "Send again"
        case verificated = ""
    }
    
    // Email page
    private let emailSymbolsLimit: Int = 64
    @Published var emailTextField: String = "" {
        didSet {
            if emailTextField.count > emailSymbolsLimit {
                emailTextField = emailTextField.truncated(limit: emailSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    private var savedEmail: String = ""
    private var oneTimePasscode: String? = nil
    @Published var emailButtonDisabled: Bool = true
    @Published var emailButtonText: EmailButtonText = .send
    @Published var emailTextFieldIsDisabled: Bool = false
    @Published var emailNextButtonDisabled: Bool = true
    
    // Timer
    @Published var showTimer: Bool = false
    @Published var timeRemaining: String = ""
    
    
    @Published var codeTextField: String = "" {
        didSet {
            if codeTextField.containsSomethingExceptNumbers() && !oldValue.containsSomethingExceptNumbers() {
                codeTextField = oldValue
            }
            if codeTextField.count > 6 {
                codeTextField = codeTextField.truncated(limit: 6, position: .tail, leader: "")
            }
        }
    }
    @Published var showCodeTextField: Bool = false
    @Published var codeCheckPassed: Bool = false
    @Published var confirmButtonDisabeld: Bool = true
    @Published var showSuccedStatusIcon: Bool = false
    @Published var showFailStatusIcon: Bool = false
    
    
    // Password page
    private let passwordSymbolsLimit: Int = 23
    @Published var passwordField: String = "" {
        didSet {
            if passwordField.count > passwordSymbolsLimit {
                passwordField = passwordField.truncated(limit: passwordSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var passwordConfirmField: String = "" {
        didSet {
            if passwordConfirmField.count > passwordSymbolsLimit {
                passwordConfirmField = passwordConfirmField.truncated(limit: passwordSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var passwordMessage: PasswordWarningMessage = .short
    @Published var passwordNextButtonDisabled: Bool = true
    @Published var changingPasswordIsLoading: Bool = false
    @Published var showDontMatchError: Bool = false
    
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
        
    
    // Cancellables publishers
    private var cancellables = Set<AnyCancellable>()
    
    func emailButtonPressed() async {
        
        savedEmail = emailTextField.lowercased()
        
        let result = await CloudKitManager.instance.doesRecordExistInPublicDatabase(inRecordType: .allUsersRecordType, withField: .emailRecordField, equalTo: savedEmail)
        switch result {
        case .success(let exist):
            if exist {
                switch self.emailButtonText {
                case .send:
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.09)) {
                            self.startTimerFor(seconds: 10)
                            self.emailButtonDisabled = true
                            self.showCodeTextField = true
                        }
                        self.emailButtonText = .again
                    }
                case .again:
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.09)) {
                            self.startTimerFor(seconds: 59)
                            self.emailButtonDisabled = true
                        }
                    }
                case .verificated: break
                }
                
                do {
                    try await self.sendEmail()
                } catch {
                    self.showAlert(title: "Error while sending e-mail", message: error.localizedDescription)
                }
            } else {
                showAlert(title: "Error", message: "Account with this e-mail does not exist")
            }
        case .failure(let failure):
            showAlert(title: "Server error", message: failure.localizedDescription)
        }
        
        
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
    
    private var futureDate = Date()
    
    private var cancellablesTimer = Set<AnyCancellable>()
    
    private func startTimerFor(seconds: Int) {
        futureDate = Calendar.current.date(byAdding: .second, value: seconds + 1, to: Date()) ?? Date()
        let remaining = Calendar.current.dateComponents([.minute, .second], from: Date(), to: self.futureDate)
        let minute = remaining.minute ?? 0
        let second = remaining.second ?? 0
        if second >= 10 {
            timeRemaining = "\(minute):\(second)"
        } else {
            timeRemaining = "\(minute):0\(second)"
        }
        showTimer = true
        Timer.publish(every: 1.0, on: .current, in: .common).autoconnect()
            .sink { _ in
                let remaining = Calendar.current.dateComponents([.minute, .second], from: Date(), to: self.futureDate)
                let minute = remaining.minute ?? 0
                let second = remaining.second ?? 0
                if second <= 0 && minute <= 0 {
                    self.showTimer = false
                    self.cancellablesTimer.first?.cancel()
                } else {
                    if second >= 10 {
                        self.timeRemaining = "\(minute):\(second)"
                    } else {
                        self.timeRemaining = "\(minute):0\(second)"
                    }
                }
            }
            .store(in: &cancellablesTimer)
        
        
    }
    
    private func sendEmail() async throws {
        
        oneTimePasscode = String.generateOneTimeCode()
        
        let to = savedEmail
        let subject = "E-mail Verification"
        let type = "text/HTML"
        let text = "<h3>Password reset</h3><br /><br />Your confirmation code is <b>\(oneTimePasscode ?? "ErRoR")</b>"
        
        let _ = try await EmailSendManager.instance.sendEmail(to: to, subject: subject, type: type, text: text)
    }
        
    func confirmButtonPressed() {
        withAnimation(.easeInOut(duration: 0.09)) {
            if codeTextField == oneTimePasscode {
                showTimer = false
                emailButtonText = .verificated
                emailTextField = savedEmail
                emailTextFieldIsDisabled = true
                withAnimation(.easeInOut.delay(0.5)) {
                    codeCheckPassed = true
                    showCodeTextField = false
                    emailNextButtonDisabled = false
                }
                withAnimation(.easeInOut.delay(1)) {
                    showSuccedStatusIcon = true
                    HapticManager.instance.notification(of: .success)
                }
            } else {
                confirmButtonDisabeld = true
                showFailStatusIcon = true
                HapticManager.instance.notification(of: .error)
            }
        }
    }
    
    func changePassword() async {
        await MainActor.run(body: {
            changingPasswordIsLoading = true
        })
        
        let newPassword = passwordField
        
        let result = await CloudKitManager.instance.recordIdOfUser(withField: .emailRecordField, inRecordType: .allUsersRecordType, equalTo: savedEmail)
        switch result {
        case .success(let recordId):
            if let recordId = recordId {
                let result = await CloudKitManager.instance.updatePasswordForUserWith(recordId: recordId, newPassword: newPassword)
                await MainActor.run {
                    changingPasswordIsLoading = false
                    switch result {
                    case .success(_):
                        withAnimation {
                            path = NavigationPath()
                        }
                        showAlertOnLogInScreen("Password reset", "Your password was successfully changes")
                    case .failure(let error):
                        showAlert(title: "Error while updating password", message: error.localizedDescription)
                    }
                }
            }
        case .failure(let error):
            await MainActor.run {
                changingPasswordIsLoading = false
                showAlert(title: "Error while finding user with this e-mail", message: error.localizedDescription)
            }
        }

    }
            
    /// Adding subscribers depending on current registration level
    private func addSubscribers() {
        let sharedEmailPublisher = $emailTextField
            .share()
        
        let sharedCodePublisher = $codeTextField
            .share()
        
        // After 0.5 second of inactivity checks whether email is correct
        sharedEmailPublisher
            .combineLatest($showTimer)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .filter({ email, _ in email.isValidEmail() && !self.showTimer })
            .sink { [weak self] _ in
                self?.emailButtonDisabled = false
            }
            .store(in: &cancellables)
        
        // Disables next button immidiatly with any field change
        sharedEmailPublisher
            .removeDuplicates()
            .filter({ _ in !self.emailButtonDisabled })
            .sink { [weak self] _ in
                self?.emailButtonDisabled = true
            }
            .store(in: &cancellables)
        
        sharedCodePublisher
            .removeDuplicates()
            .map({ $0.count == 6 })
            .sink { [weak self] receivedValue in
                self?.confirmButtonDisabeld = !receivedValue
            }
            .store(in: &cancellables)
        
        sharedCodePublisher
            .removeDuplicates()
            .filter({ _ in self.showFailStatusIcon })
            .sink { [weak self] _ in
                self?.showFailStatusIcon = false
            }
            .store(in: &cancellables)
        
        let sharedPasswordPublisher = $passwordField
            .combineLatest($passwordConfirmField)
            .share()
        
        sharedPasswordPublisher
            .debounce(for: 2.0, scheduler: DispatchQueue.main)
            .filter({ $0 != $1 })
            .sink { [weak self] _, _ in
                self?.showDontMatchError = true
            }
            .store(in: &cancellables)
        
        sharedPasswordPublisher
            .debounce(for: 0.7, scheduler: DispatchQueue.main)
            .map(mapPasswords)
            .sink(receiveValue: { [weak self] passed, message in
                if passed {
                    self?.passwordNextButtonDisabled = false
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.passwordMessage = message
                }
            })
            .store(in: &cancellables)
        
        sharedPasswordPublisher
            .filter( { _, _ in !self.passwordNextButtonDisabled || self.showDontMatchError })
            .sink { [weak self] _, _ in
                self?.showDontMatchError = false
                self?.passwordNextButtonDisabled = true
            }
            .store(in: &cancellables)
    }
    
    /// Returnes bool and PasswordWarningMessage where bool is true if password passed check and equals confirmation field
    private func mapPasswords(_ password: String, _ confirmation: String) -> (Bool, PasswordWarningMessage) {
        if password.count < 8 { return (false, .short) } else {
            if password.containsUnacceptableSymbols() { return (false, .unacceptableSymbols) } else {
                var uniqueSpecialSymbols: [String] = []
                var uniqueCapitalLetters: [String] = []
                var uniqueLowercasedLetters: [String] = []
                var uniqueNumbers: [String] = []
                
                
                
                for char in password {
                    if char.existsInSet(of: String.specialSymbols) {
                        uniqueSpecialSymbols.append("\(char)")
                    }
                    if char.existsInSet(of: String.capitalLetters) {
                        uniqueCapitalLetters.append("\(char)")
                    }
                    if char.existsInSet(of: String.lowercasedLetters) {
                        uniqueLowercasedLetters.append("\(char)")
                    }
                    if char.existsInSet(of: String.numbers) {
                        uniqueNumbers.append("\(char)")
                    }
                }
                
                uniqueSpecialSymbols = Array(Set(uniqueSpecialSymbols))
                uniqueCapitalLetters = Array(Set(uniqueCapitalLetters))
                uniqueLowercasedLetters = Array(Set(uniqueLowercasedLetters))
                uniqueNumbers = Array(Set(uniqueNumbers))
                if password.count > 12 && password.containsLowercasedLetters() && password.containsNumbers() && password.containsCapitalLetters() && password.containsSpecialSymbols() && uniqueSpecialSymbols.count >= 2 &&
                    (uniqueNumbers.count >= 3 || uniqueLowercasedLetters.count >= 3 || uniqueCapitalLetters.count >= 3) {
                    return (password == confirmation, .veryStrong)
                } else if password.count > 10 && password.containsLowercasedLetters() && password.containsNumbers() && (password.containsCapitalLetters() || password.containsSpecialSymbols()) && (uniqueCapitalLetters.count >= 3 || uniqueSpecialSymbols.count >= 2) && (uniqueNumbers.count >= 3 || uniqueLowercasedLetters.count >= 3) {
                    return (password == confirmation, .strong)
                } else if password.containsLowercasedLetters() && password.containsNumbers() && password.containsCapitalLetters() && uniqueLowercasedLetters.count >= 2  && (uniqueNumbers.count >= 2 || uniqueCapitalLetters.count >= 2) {
                    return (password == confirmation, .medium)
                } else if password.containsNumbers() && (password.containsLowercasedLetters() || password.containsCapitalLetters()) {
                    return (password == confirmation, .weak)
                } else {
                    return (false, .numbersAndLetters)
                }
            }
        }
    }
    
}