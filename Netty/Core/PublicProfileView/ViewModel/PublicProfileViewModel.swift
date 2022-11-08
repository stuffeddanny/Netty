//
//  PublicProfileViewModel.swift
//  Netty
//
//  Created by Danny on 11/8/22.
//

import SwiftUI
import CloudKit

class PublicProfileViewModel: ObservableObject {
    
    // Alert data
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""

    let user: UserModel
    
    @Published var userInfoIsLoading: Bool = true
    @Published var postsAreLoading: Bool = true
    
    // Posts array
    @Published var posts: [PostModel] = []
    
    // User's first name
    @Published var firstName: String = ""
    
    // User's last name
    @Published var lastName: String = ""
    
    // User's nickname
    @Published var nickname: String = ""
    
    private let cacheManager = CacheManager.instance
    
    init(_ userModel: UserModel) {
        user = userModel
        
        Task {
            await getUserData()
            await getUserPosts()
        }
    }
    
    private func getUserData() async {
        await MainActor.run {
            userInfoIsLoading = true
        }
        
        if let savedUser = cacheManager.getFrom(cacheManager.userData, key: user.id.recordName) {
            await MainActor.run {
                firstName = savedUser.user.firstName
                lastName = savedUser.user.lastName
                nickname = savedUser.user.nickname
                
                userInfoIsLoading = false
            }
            switch await UserInfoService.instance.fetchUserDataForUser(with: user.id) {
            case .success(let userModel):
                if let userModel = userModel, userModel != savedUser.user {
                    cacheManager.addTo(cacheManager.userData, key: user.id.recordName, value: UserModelHolder(userModel))
                    await MainActor.run {
                        firstName = userModel.firstName
                        lastName = userModel.lastName
                        nickname = userModel.nickname
                        
                        userInfoIsLoading = false
                    }
                }
            case .failure(_):
                break
            }
        } else {
            switch await UserInfoService.instance.fetchUserDataForUser(with: user.id) {
            case .success(let userModel):
                if let userModel = userModel {
                    cacheManager.addTo(cacheManager.userData, key: user.id.recordName, value: UserModelHolder(userModel))
                    await MainActor.run {
                        firstName = userModel.firstName
                        lastName = userModel.lastName
                        nickname = userModel.nickname
                        
                        userInfoIsLoading = false
                    }
                } else {
                    showAlert(title: "Error while fetching user data", message: "Cannot fetch some parameters")
                    await MainActor.run {
                        userInfoIsLoading = false
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while fetching user data", message: error.localizedDescription)
                await MainActor.run {
                    userInfoIsLoading = false
                }
            }
        }    }
    
    private func getUserPosts() async {
        await MainActor.run {
            postsAreLoading = true
        }
        
        if let savedPosts = cacheManager.getFrom(cacheManager.posts, key: user.id.recordName) {
            await MainActor.run {
                posts = savedPosts.posts
                withAnimation {
                    postsAreLoading = false
                }
            }
            
            switch await PostsService.instance.getPostsForUserWith(user.id) {
            case .success(let postArray):
                if postArray != savedPosts.posts {
                    cacheManager.addTo(cacheManager.posts, key: user.id.recordName, value: PostModelsHolder(postArray))
                    await MainActor.run {
                        withAnimation {
                            posts = postArray
                        }
                    }
                }
            case .failure(_):
                break
            }
            
        } else {
            switch await PostsService.instance.getPostsForUserWith(user.id) {
            case .success(let postArray):
                cacheManager.addTo(cacheManager.posts, key: user.id.recordName, value: PostModelsHolder(postArray))
                await MainActor.run {
                    posts = postArray
                    withAnimation {
                        postsAreLoading = false
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while fetching posts", message: error.localizedDescription)
            }
        }
    }
    
    /// Deletes user's data from cache and downloads new fresh data from database
    func sync() async {
        await getUserData()
        await getUserPosts()
    }
    
    /// Shows alert on the screen
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }

}
