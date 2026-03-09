//
//  ServicesMealPlanSensitivitySettingsTests.swift
//  pantryTests
//

import Testing
@testable import pantry

struct MealPlanSensitivitySettingsTests {

    @Test func decodeSensitivityCSV_deduplicatesAndIgnoresUnknownValues() {
        let decoded = MealPlanSensitivitySettings.decodeSensitivityCSV("peanut,soy,peanut,unknown")
        #expect(decoded == [.peanut, .soy])
    }

    @Test func encodeSensitivityCSV_keepsStableOrderWithoutDuplicates() {
        let encoded = MealPlanSensitivitySettings.encodeSensitivityCSV([.egg, .dairy, .egg])
        #expect(encoded == "egg,dairy")
    }

    @Test func decodeCustomTags_splitsCommaAndNewlineAndNormalizesCase() {
        let tags = MealPlanSensitivitySettings.decodeCustomTags("Nightshade, sesame\nNightshade,  ")
        #expect(tags == ["nightshade", "sesame"])
    }
}
