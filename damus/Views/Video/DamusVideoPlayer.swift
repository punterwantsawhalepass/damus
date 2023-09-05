//
//  VideoPlayerView.swift
//  damus
//
//  Created by William Casarin on 2023-04-05.
//

import SwiftUI

/// get coordinates in Global reference frame given a Local point & geometry
func globalCoordinate(localX x: CGFloat, localY y: CGFloat,
                      localGeometry geo: GeometryProxy) -> CGPoint {
    let localPoint = CGPoint(x: x, y: y)
    return geo.frame(in: .global).origin.applying(
        .init(translationX: localPoint.x, y: localPoint.y)
    )
}

struct DamusVideoPlayer: View {
    var url: URL
    @ObservedObject var model: VideoPlayerModel
    @Binding var video_size: CGSize?
    @EnvironmentObject private var orientationTracker: OrientationTracker

    // Move centerY and delta here
    let localFrame: CGRect
    let centerY: CGFloat
    let delta: CGFloat

    init(url: URL, model: VideoPlayerModel, video_size: Binding<CGSize?>, orientationTracker: EnvironmentObject<OrientationTracker>) {
        self.url = url
        self.model = model
        self._video_size = video_size
        self._orientationTracker = orientationTracker

        // Calculate localFrame, centerY, and delta
        self.localFrame = CGRect(x: 0, y: 0, width: 0, height: 0) // Update with appropriate initial values
        self.centerY = 0 // Update with appropriate initial values
        self.delta = 0 // Update with appropriate initial values
    }

    var mute_icon: String {
        if model.has_audio == false || model.muted {
            return "speaker.slash"
        } else {
            return "speaker"
        }
    }

    var mute_icon_color: Color {
        switch self.model.has_audio {
        case .none:
            return .white
        case .some(let has_audio):
            return has_audio ? .white : .red
        }
    }

    var MuteIcon: some View {
        ZStack {
            Circle()
                .opacity(0.2)
                .frame(width: 32, height: 32)
                .foregroundColor(.black)

            Image(systemName: mute_icon)
                .padding()
                .foregroundColor(mute_icon_color)
        }
    }

    private func controlVideoPlayback() {
        if shouldPlayVideo(centerY: centerY, delta: delta) && !isPlaying {
            isPlaying = true
            model.start()
        } else if !shouldPlayVideo(centerY: centerY, delta: delta) && isPlaying {
            isPlaying = false
            model.stop()
        }
    }

    var body: some View {
        GeometryReader { geo in
            let localFrame = geo.frame(in: .local)
            let centerY = globalCoordinate(localX: 0, localY: localFrame.midY, localGeometry: geo).y
            let delta = localFrame.height / 2
            ZStack(alignment: .bottomTrailing) {
                VideoPlayer(url: url, model: model)
                if model.has_audio == true {
                    MuteIcon
                        .zIndex(11.0)
                        .onTapGesture {
                            self.model.muted = !self.model.muted
                        }
                }
            }
            .onChange(of: model.size) { size in
                guard let size else {
                    return
                }
                video_size = size
            }
            .onChange(of: centerY) { _ in
                /// pause video when it is scrolled beyond the visible range
                let isBelowTop = centerY + delta > 100, /// 100 =~ approx. bottom (y) of ContentView's TabView
                    isAboveBottom = centerY - delta < orientationTracker.deviceMajorAxis
                if isBelowTop && isAboveBottom {
                    model.start()
                } else {
                    model.stop()
                }
            }
            .onChange(of: isPlaying) { _ in
                controlVideoPlayback() // Call controlVideoPlayback when isPlaying changes
            }
        }
    }
}

struct DamusVideoPlayer_Previews: PreviewProvider {
    @StateObject static var model: VideoPlayerModel = VideoPlayerModel()

    static var previews: some View {
        DamusVideoPlayer(url: URL(string: "http://cdn.jb55.com/s/zaps-build.mp4")!, model: model, video_size: .constant(nil))
            .environmentObject(OrientationTracker()) // Provide a valid OrientationTracker
    }
}
