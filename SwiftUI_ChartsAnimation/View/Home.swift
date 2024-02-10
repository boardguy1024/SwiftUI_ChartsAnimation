//
//  Home.swift
//  SwiftUI_ChartsAnimation
//
//  Created by paku on 2024/02/10.
//

import SwiftUI
import Charts

struct Home: View {
    
    @State var sampleAnalytics: [SiteView] = sample_analytics
    @State var currentTab: String = "7 Days"
    @State var currentActiveItem: SiteView?
    @State var plotWidth: CGFloat = 0
    @State var isLineGraph: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Views")
                            .fontWeight(.semibold)
                        Picker("", selection: $currentTab) {
                            Text("7 Days")
                                .tag("7 Days")
                            Text("Week")
                                .tag("Week")
                            Text("Month")
                                .tag("Month")
                        }
                        .pickerStyle(.segmented)
                        .padding(.leading, 80)
                    }
                    
                    let totalValue = sampleAnalytics.reduce(0.0) { partialResult, item in
                        return item.views + partialResult
                    }
                    
                    Text("\(totalValue.stringFormat)")
                        .font(.largeTitle.bold())
                    AnimatedChart()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.shadow(.drop(radius: 10)))
                )
                
                Toggle("Line Graph", isOn: $isLineGraph)
                    .padding(.horizontal, 4)
                    .padding(.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            .navigationTitle("Charts")
            .onChange(of: currentTab) { _, _ in
                animationGraph(fromTabChange: true)
            }
        }
    }
    
    @ViewBuilder
    func AnimatedChart() -> some View {
        Chart {
            ForEach(sampleAnalytics) { item in
                
                if isLineGraph {
                    LineMark(
                        x: .value("Hour", item.hour, unit: .hour),
                        y: .value("Views", item.animate ? item.views : 0)
                    )
                    .foregroundStyle(Color.red.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Hour", item.hour, unit: .hour),
                        y: .value("Views", item.animate ? item.views : 0)
                    )
                    .foregroundStyle(Color.red.gradient.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                } else {
                    BarMark(
                        x: .value("Hour", item.hour, unit: .hour),
                        y: .value("Views", item.animate ? item.views : 0)
                    )
                    .foregroundStyle(Color.red.gradient)
                }
                
                if let currentActiveItem, currentActiveItem.id == item.id {
                    RuleMark(x: .value("Hour", currentActiveItem.hour))
                        .lineStyle(.init(dash: [2]))
                        .offset(x: plotWidth / CGFloat(sampleAnalytics.count) / 2)
                        .foregroundStyle(.red.gradient)
                        .annotation(position: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Views")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(currentActiveItem.views.stringFormat)
                                    .font(.title3.bold())
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(.white.shadow(.drop(radius: 5)))
                            }
                        }
                }
            }
        }
        .chartYScale(domain: 0...15000)
        .chartOverlay(content: { chartProxy in
            GeometryReader { proxy in
                Rectangle()
                    .fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged({ value in
                                let location = value.location
                                
                                // ChartProxyからDragしたTargetのX座標にある valueを取得
                                if let date: Date = chartProxy.value(atX: location.x) {
                                    let calendar = Calendar.current
                                    let hour = calendar.component(.hour, from: date)
                                    
                                    // hourをKeyとしてそれに紐づくvalueを取得
                                    if let currentItem = sampleAnalytics.first(where: { item in
                                        calendar.component(.hour, from: item.hour) == hour
                                    }) {
                                        self.currentActiveItem = currentItem
                                        // graphAreaのWidth
                                        self.plotWidth = chartProxy.plotSize.width
                                    }
                                    
                                }
                            })
                            .onEnded({ value in
                                withAnimation {
                                    self.currentActiveItem = nil
                                }
                            })
                    )
            }
        })
        .frame(height: 250)
        .onAppear {
            animationGraph()
        }
    }
    
    // タブ切り替えの場合、animationを通常より早めに行う
    func animationGraph(fromTabChange: Bool = false) {
        for (index, _) in sampleAnalytics.enumerated() {
            sampleAnalytics = sample_analytics
            DispatchQueue.main.asyncAfter(deadline: .now() + CGFloat(index) * (fromTabChange ? 0.03 : 0.05)) {
                withAnimation(.bouncy(duration: 0.8)) {
                    sampleAnalytics[index].animate = true
                }
            }
        }
    }
}

#Preview {
    ContentView ()
}

extension Double {
    var stringFormat: String {
        if self > 10000 && self < 9999999 {
            return String(format: "%.1fK", self / 1000).replacingOccurrences(of: ".0", with: "")
        }
        if self > 9999999 {
            return String(format: "%.1fM", self / 100000).replacingOccurrences(of: ".0", with: "")
        }
        return String(format: "%.1f", self)
    }
}
