//
//  BannerImageView.swift
//  damus
//
//  Created by Jason Jōb on 2023-01-10.
//

import SwiftUI
import Kingfisher

struct EditBannerImageView: View {
    
    var damus_state: DamusState
    @ObservedObject var viewModel: ImageUploadingObserver
    let callback: (URL?) -> Void
    let defaultImage = UIImage(named: "profile-banner") ?? UIImage()
    
    @State var banner_image: URL? = nil

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            KFAnimatedImage(get_banner_url(banner: banner_image?.absoluteString, pubkey: damus_state.pubkey, profiles: damus_state.profiles))
                .imageContext(.banner, disable_animation: damus_state.settings.disable_animation)
                .configure { view in
                    view.framePreloadCount = 3
                }
                .placeholder { _ in
                    Color(uiColor: .secondarySystemBackground)
                }
                .onFailureImage(defaultImage)
            
            EditPictureControl(uploader: damus_state.settings.default_media_uploader, pubkey: damus_state.pubkey, image_url: $banner_image, uploadObserver: viewModel, callback: callback)
        }
    }
}

struct InnerBannerImageView: View {
    let disable_animation: Bool
    let url: URL?
    let defaultImage = UIImage(named: "profile-banner") ?? UIImage()

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            
            if (url != nil) {
                KFAnimatedImage(url)
                    .imageContext(.banner, disable_animation: disable_animation)
                    .configure { view in
                        view.framePreloadCount = 3
                    }
                    .placeholder { _ in
                        Color(uiColor: .secondarySystemBackground)
                    }
                    .onFailureImage(defaultImage)
            } else {
                Image(uiImage: defaultImage).resizable()
            }
        }
    }
}

struct BannerImageView: View {
    let disable_animation: Bool
    let pubkey: Pubkey
    let profiles: Profiles
    
    @State var banner: String?
    
    init(pubkey: Pubkey, profiles: Profiles, disable_animation: Bool, banner: String? = nil) {
        self.pubkey = pubkey
        self.profiles = profiles
        self._banner = State(initialValue: banner)
        self.disable_animation = disable_animation
    }
    
    var body: some View {
        InnerBannerImageView(disable_animation: disable_animation, url: get_banner_url(banner: banner, pubkey: pubkey, profiles: profiles))
            .onReceive(handle_notify(.profile_updated)) { updated in
                guard updated.pubkey == self.pubkey else {
                    return
                }
                
                if let bannerImage = updated.profile.banner {
                    self.banner = bannerImage
                }
            }
    }
}

func get_banner_url(banner: String?, pubkey: Pubkey, profiles: Profiles) -> URL? {
    let bannerUrlString = banner ?? profiles.lookup(id: pubkey)?.banner ?? ""
    if let url = URL(string: bannerUrlString) {
        return url
    }
    return nil
}

struct BannerImageView_Previews: PreviewProvider {
    static var previews: some View {
        BannerImageView(
            pubkey: test_pubkey,
            profiles: make_preview_profiles(test_pubkey),
            disable_animation: false
        )
    }
}

