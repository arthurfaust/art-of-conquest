extends RefCounted

# Calcula probabilidades a partir dos níveis conhecidos, sem acessar o tabuleiro.
# known_levels deve conter reveladas vivas + eliminadas, uma vez por unidade.
const INITIAL_RED_COUNTS = {
	1: 2,
	2: 2,
	3: 2,
	4: 2
}

static func get_unknown_red_counts(known_levels: Array[int] = []) -> Dictionary:
	var remaining = INITIAL_RED_COUNTS.duplicate()

	for level in known_levels:
		if remaining.has(level):
			remaining[level] -= 1

	return remaining

static func get_unknown_red_total(known_levels: Array[int] = []) -> int:
	var counts = get_unknown_red_counts(known_levels)
	var total = 0

	for level in counts:
		total += counts[level]

	return total

static func get_level_probabilities(known_levels: Array[int] = []) -> Dictionary:
	var counts = get_unknown_red_counts(known_levels)
	var total = get_unknown_red_total(known_levels)

	var probabilities = {}

	for level in counts:
		if total > 0:
			probabilities[level] = float(counts[level]) / float(total)
		else:
			probabilities[level] = 0.0

	return probabilities

static func get_combat_probabilities(blue_level: int, known_levels: Array[int] = []) -> Dictionary:
	var counts = get_unknown_red_counts(known_levels)
	var total = get_unknown_red_total(known_levels)

	var wins = 0
	var draws = 0
	var losses = 0

	for red_level in counts:
		var quantity = counts[red_level]

		if blue_level > red_level:
			wins += quantity

		elif blue_level == red_level:
			draws += quantity

		else:
			losses += quantity

	if total == 0:
		return {
			"wins": 0,
			"draws": 0,
			"losses": 0,
			"total": 0,
			"win_probability": 0.0,
			"draw_probability": 0.0,
			"loss_probability": 0.0
		}

	return {
		"wins": wins,
		"draws": draws,
		"losses": losses,
		"total": total,
		"win_probability": float(wins) / float(total),
		"draw_probability": float(draws) / float(total),
		"loss_probability": float(losses) / float(total)
	}

static func factorial(n: int) -> int:
	var result = 1

	for i in range(2, n + 1):
		result *= i

	return result

static func get_sample_space_size(known_levels: Array[int] = []) -> int:
	var counts = get_unknown_red_counts(known_levels)
	var total = get_unknown_red_total(known_levels)

	if total == 0:
		return 1

	var denominator = 1

	for level in counts:
		denominator *= factorial(counts[level])

	@warning_ignore("integer_division")
	return factorial(total) / denominator

static func get_uncertainty_reduction(known_levels: Array[int] = []) -> float:
	var initial_sample_space = get_sample_space_size()
	var current_sample_space = get_sample_space_size(known_levels)

	return 1.0 - (
		float(current_sample_space)
		/ float(initial_sample_space)
	)

