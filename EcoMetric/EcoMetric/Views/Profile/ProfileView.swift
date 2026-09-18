//
//  ProfileView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct ProfileView: View {

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    spacing: 22
                ) {

                    profileHeader

                    companyCard

                    settingsSection

                    aboutSection
                }
                .padding()
            }
            .background(
                EcoTheme.background
                    .ignoresSafeArea()
            )
            .navigationTitle(
                "Tài khoản"
            )
        }
    }

    private var profileHeader: some View {

        VStack(
            spacing: 12
        ) {

            ZStack {

                Circle()
                    .fill(
                        EcoTheme.lightGreen
                    )
                    .frame(
                        width: 90,
                        height: 90
                    )

                Image(
                    systemName:
                        "building.2.fill"
                )
                .font(
                    .system(size: 36)
                )
                .foregroundStyle(
                    EcoTheme.green
                )
            }

            Text(
                "EcoMetric Demo"
            )
            .font(
                .title2.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "Tài khoản doanh nghiệp"
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )
        }
        .frame(
            maxWidth: .infinity
        )
    }

    private var companyCard: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "Thông tin doanh nghiệp"
            )
            .font(
                .headline
            )

            infoRow(
                icon:
                    "building.fill",
                title:
                    "Tên doanh nghiệp",
                value:
                    "EcoMetric Demo"
            )

            Divider()

            infoRow(
                icon:
                    "location.fill",
                title:
                    "Khu vực",
                value:
                    "Việt Nam"
            )

            Divider()

            infoRow(
                icon:
                    "leaf.fill",
                title:
                    "Mục tiêu",
                value:
                    "Giảm phát thải"
            )
        }
        .padding()
        .background(
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    private var settingsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text(
                "Cài đặt"
            )
            .font(.headline)

            settingsRow(
                icon:
                    "bell.fill",
                title:
                    "Thông báo"
            )

            settingsRow(
                icon:
                    "slider.horizontal.3",
                title:
                    "Tùy chỉnh dữ liệu"
            )

            settingsRow(
                icon:
                    "lock.fill",
                title:
                    "Bảo mật"
            )
        }
    }

    private var aboutSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text(
                "Khác"
            )
            .font(.headline)

            settingsRow(
                icon:
                    "questionmark.circle.fill",
                title:
                    "Trợ giúp"
            )

            settingsRow(
                icon:
                    "info.circle.fill",
                title:
                    "Giới thiệu EcoMetric"
            )
        }
    }

    private func infoRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        HStack {

            Image(
                systemName:
                    icon
            )
            .foregroundStyle(
                EcoTheme.green
            )
            .frame(
                width: 30
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(
                    title
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Text(
                    value
                )
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
            }

            Spacer()
        }
    }

    private func settingsRow(
        icon: String,
        title: String
    ) -> some View {

        HStack {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 10
                )
                .fill(
                    EcoTheme.lightBlue
                )
                .frame(
                    width: 40,
                    height: 40
                )

                Image(
                    systemName:
                        icon
                )
                .foregroundStyle(
                    EcoTheme.blue
                )
            }

            Text(
                title
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Spacer()

            Image(
                systemName:
                    "chevron.right"
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding()
        .background(
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }
}
