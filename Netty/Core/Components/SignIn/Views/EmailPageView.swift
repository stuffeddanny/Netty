//
//  EmailPageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct EmailPageView: View {
    
    @ObservedObject private var vm: SignUpViewModel
    
    @FocusState private var isEmailFieldActive: Bool

    init(vm: SignUpViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        NavigationView {
            VStack() {
                
                // Subtitle
                Text("Enter your e-mail")
                    .padding()
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // TextField
                TextField("E-mail", text: $vm.emailTextField) { !vm.nextButtonIsDisabled ? vm.moveToTheNextRegistrationLevel() : UIApplication.shared.endEditing() }
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .focused($isEmailFieldActive)
                    .padding()
                    .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                        isEmailFieldActive = true
                    })
                    .padding()
                
                Spacer()
                
                // Buttons
                HStack {
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
            .navigationTitle("Create account")
            .background(Color.theme.background.ignoresSafeArea().onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
}

