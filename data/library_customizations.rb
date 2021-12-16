# A number of issues were found in Google"s dataset and reported at.
# https://github.com/googlei18n/libaddressinput/issues
#
# Since Google has been slow to resolve them, the library maintains its own
# list of customizations, in Ruby format for easier contribution.

# Returns the address format customizations for the provided country code.
def address_format_customizations(country_code)
  format_customizations = {}

  # Replace the postal code pattern.
  # https://github.com/google/libaddressinput/issues/207
  format_customizations["BH"] = {
    "postal_code_pattern" => "(?:^|\b)(?:1[0-2]|[1-9])\d{2}(?:$|\b)"
  }

  # Make the locality required.
  format_customizations["CO"] = {
    "required_fields" => [
      "address_line1", "locality", "administrative_area"
    ]
  }

  # Switch %organization and %recipient.
  # https://github.com/googlei18n/libaddressinput/issues/83
  format_customizations["DE"] = {
    "format" => "%organization\n%given_name %family_name\n%address_line1\n%address_line2\n%postalCode %locality"
  }

  # Revert the removal of %sortingCode.
  # https://github.com/google/libaddressinput/issues/177
  format_customizations ["FR"] = {
    "format" => "%organization\n%given_name %family_name\n%address_line1\n%address_line2\n%postal_code %locality %sorting_code"
  }

  # Make the postal codes required, add administrative area fields (EE, LT).
  # https://github.com/googlei18n/libaddressinput/issues/64
  format_customizations["EE"] = {
    "format" => "%given_name %family_name\n%organization\n%address_line1\n%address_line2\n%postal_code %locality %administrative_area",
    "required_fields" => [
      "address_line1",
      "locality",
      "postal_code"
    ],
    "administrative_area_type" => "county"
  }

  # Revert the removal of %locality.
  # https://github.com/google/libaddressinput/issues/177
  format_customizations["JP"] = {
    "format" => "%family_name %given_name\n%organization\n%address_line1\n%address_line2\n%locality, %administrative_area\n%postal_code",
    "local_format" => "〒%postal_code\n%administrative_area%locality\n%address_line1\n%address_line2\n%organization\n%family_name %given_name"
  }

  format_customizations["LT"] = {
    "format" => "%organization\n%given_name %family_name\n%address_line1\n%address_line2\n%postal_code %locality %administrative_area",
    "required_fields" => [
      "address_line1",
      "locality",
      "postal_code"
    ],
    "administrative_area_type" => "county"
  }

  format_customizations["LV"] = {
    "required_fields" => [
      "address_line1",
      "locality",
      "postal_code"
    ]
  }

  format_customizations.key?(country_code) ? format_customizations[country_code] : {}
end

# Returns the subdivision customizations for the provided group.
def subdivision_customizations(group)
  subdivision_customizations = {}

  # Adds Colombian subdivisions
  # https://github.com/googlei18n/libaddressinput/issues/135
  subdivision_customizations["CO"] = {
    "_add" => [
      "DC", "AMA", "ANT", "ARA", "ATL", "BOL", "BOY",
      "CAL", "CAQ", "CAS", "CAU", "CES", "COR", "CUN",
      "CHO", "GUA", "GUV", "HUI", "LAG", "MAG", "MET",
      "NAR", "NSA", "PUT", "QUI", "RIS", "SAP", "SAN",
      "SUC", "TOL", "VAC", "VAU", "VID"
    ],
    "DC" => {
      "name" => "Distrito Capital de Bogotá",
      "iso_code" => "CO-DC",
      "postal_code_pattern" => "11\d{4}"
    },
    "AMA" => {
      "name" => "Amazonas",
      "iso_code" => "CO-AMA",
      "postal_code_pattern" => "91\d{4}"
    },
    "ANT" => {
      "name" => "Antioquia",
      "iso_code" => "CO-ANT",
      "postal_code_pattern" => "05\d{4}"
    },
    "ARA" => {
      "name" => "Arauca",
      "iso_code" => "CO-ARA",
      "postal_code_pattern" => "81\d{4}"
    },
    "ATL" => {
      "name" => "Atlántico",
      "iso_code" => "CO-ATL",
      "postal_code_pattern" => "08\d{4}"
    },
    "BOL" => {
      "name" => "Bolívar",
      "iso_code" => "CO-BOL",
      "postal_code_pattern" => "13\d{4}"
    },
    "BOY" => {
      "name" => "Boyacá",
      "iso_code" => "CO-BOY",
      "postal_code_pattern" => "15\d{4}"
    },
    "CAL" => {
      "name" => "Caldas",
      "iso_code" => "CO-CAL",
      "postal_code_pattern" => "17\d{4}"
    },
    "CAQ" => {
      "name" => "Caquetá",
      "iso_code" => "CO-CAQ",
      "postal_code_pattern" => "18\d{4}"
    },
    "CAS" => {
      "name" => "Casanare",
      "iso_code" => "CO-CAS",
      "postal_code_pattern" => "85\d{4}"
    },
    "CAU" => {
      "name" => "Cauca",
      "iso_code" => "CO-CAU",
      "postal_code_pattern" => "19\d{4}"
    },
    "CES" => {
      "name" => "Cesar",
      "iso_code" => "CO-CES",
      "postal_code_pattern" => "20\d{4}"
    },
    "COR" => {
      "name" => "Córdoba",
      "iso_code" => "CO-COR",
      "postal_code_pattern" => "23\d{4}"
    },
    "CUN" => {
      "name" => "Cundinamarca",
      "iso_code" => "CO-CUN",
      "postal_code_pattern" => "25\d{4}"
    },
    "CHO" => {
      "name" => "Chocó",
      "iso_code" => "CO-CHO",
      "postal_code_pattern" => "27\d{4}"
    },
    "GUA" => {
      "name" => "Guanía",
      "iso_code" => "CO-GUA",
      "postal_code_pattern" => "94\d{4}"
    },
    "GUV" => {
      "name" => "Guaviare",
      "iso_code" => "CO-GUV",
      "postal_code_pattern" => "95\d{4}"
    },
    "HUI" => {
      "name" => "Huila",
      "iso_code" => "CO-HUI",
      "postal_code_pattern" => "41\d{4}"
    },
    "LAG" => {
      "name" => "La Guajira",
      "iso_code" => "CO-LAG",
      "postal_code_pattern" => "44\d{4}"
    },
    "MAG" => {
      "name" => "Magdalena",
      "iso_code" => "CO-MAG",
      "postal_code_pattern" => "47\d{4}"
    },
    "MET" => {
      "name" => "Meta",
      "iso_code" => "CO-MET",
      "postal_code_pattern" => "50\d{4}"
    },
    "NAR" => {
      "name" => "Nariño",
      "iso_code" => "CO-NAR",
      "postal_code_pattern" => "52\d{4}"
    },
    "NSA" => {
      "name" => "Norte de Santander",
      "iso_code" => "CO-NSA",
      "postal_code_pattern" => "54\d{4}"
    },
    "PUT" => {
      "name" => "Putumayo",
      "iso_code" => "CO-PUT",
      "postal_code_pattern" => "86\d{4}"
    },
    "QUI" => {
      "name" => "Quindío",
      "iso_code" => "CO-QUI",
      "postal_code_pattern" => "63\d{4}"
    },
    "RIS" => {
      "name" => "Risaralda",
      "iso_code" => "CO-RIS",
      "postal_code_pattern" => "66\d{4}"
    },
    "SAP" => {
      "name" => "San Andrés, Providencia y Santa Catalina",
      "iso_code" => "CO-SAP",
      "postal_code_pattern" => "88\d{4}"
    },
    "SAN" => {
      "name" => "Santander",
      "iso_code" => "CO-SAN",
      "postal_code_pattern" => "68\d{4}"
    },
    "SUC" => {
      "name" => "Sucre",
      "iso_code" => "CO-SUC",
      "postal_code_pattern" => "70\d{4}"
    },
    "TOL" => {
      "name" => "Tolima",
      "iso_code" => "CO-TOL",
      "postal_code_pattern" => "73\d{4}"
    },
    "VAC" => {
      "name" => "Valle del Cauca",
      "iso_code" => "CO-VAC",
      "postal_code_pattern" => "76\d{4}"
    },
    "VAU" => {
      "name" => "Vaupés",
      "iso_code" => "CO-VAU",
      "postal_code_pattern" => "97\d{4}"
    },
    "VID" => {
      "name" => "Vichada",
      "iso_code" => "CO-VID",
      "postal_code_pattern" => "99\d{4}"
    }
  }

  subdivision_customizations.key?(group) ? subdivision_customizations[group] : {}
end
