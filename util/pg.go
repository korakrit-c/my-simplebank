package util

func PgCodeName(code string) string {
	switch code {
	case "23505":
		return "unique_violation"
	case "23503":
		return "foreign_key_violation"
	case "23502":
		return "not_null_violation"
	case "23514":
		return "check_violation"
	case "22001":
		return "string_data_right_truncation"
	default:
		return "unknown"
	}
}
