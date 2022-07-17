//
//  CreatePasswordPageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct CreatePasswordPageView: View {
    
    @ObservedObject private var vm: SignUpViewModel
    
    enum FocusedValue {
        case pass, confPass
    }
    
    @FocusState private var activeField: FocusedValue?
    
    init(vm: SignUpViewModel) {
        self.vm = vm
    }
    
    
    var body: some View {
        NavigationView {
            VStack() {
                
                // Subtitle
                Text("It's time to create a password")
                    .padding()
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Fields
                VStack(spacing: 10) {
                    
                    Spacer()
                    
                    SecureInputView("Password", text: $vm.passwordField) { activeField = .confPass }
                        
                        .textContentType(.newPassword)
                        .focused($activeField, equals: .pass)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            activeField = .pass
                        })
                    
                    PasswordStrongLevelView(message: $vm.passwordMessage)
                    
                    SecureInputView("Confirm password", text: $vm.passwordConfirmField) { !vm.nextButtonIsDisabled ? vm.moveToTheNextRegistrationLevel() : UIApplication.shared.endEditing() }
                        .textContentType(.newPassword)
                        .focused($activeField, equals: .confPass)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            activeField = .confPass
                        })
                    
                    
                    Spacer()
                    
                }
                .padding()
                
                Spacer()
                
                // Buttons
                HStack {
                    
                    // Back button
                    Button {
                        vm.moveToThePreviousRegistrationLevel()
                    } label: {
                        Text("Back")
                            .padding(.horizontal, 5)
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .padding()
                    
                    Spacer()
                    
                    // Next button
                    Button {
                        vm.moveToTheNextRegistrationLevel()
                    } label: {
                        Text("Next")
                            .padding(.horizontal, 5)
                            .font(.title3)
                    }
                    .disabled(vm.nextButtonIsDisabled)
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Create a Password")
            .background(Color.theme.background.ignoresSafeArea().onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
}

struct CreatePasswordPageView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePasswordPageView(vm: SignUpViewModel())
            .preferredColorScheme(.light)
        CreatePasswordPageView(vm: SignUpViewModel())
            .preferredColorScheme(.dark)
    }
}
