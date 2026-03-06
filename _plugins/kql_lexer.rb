# Custom Rouge lexer for KQL (Kusto Query Language)
# Used in Azure Monitor, Microsoft Sentinel, Azure Data Explorer, etc.
require 'rouge'

module Rouge
  module Lexers
    class KQL < Rouge::RegexLexer
      title "KQL"
      desc "Kusto Query Language (Azure Monitor, Microsoft Sentinel, Azure Data Explorer)"

      tag 'kql'
      aliases 'kusto'
      filenames '*.kql', '*.kusto'
      mimetypes 'text/x-kql', 'application/x-kusto'

      # Tabular operators
      TABULAR_OPERATORS = %w[
        where project extend summarize join union count limit take top
        sort order by distinct sample parse mv-expand mv-apply evaluate
        render search externaldata datatable getschema print reduce
        partition invoke pivot scan serialize
        project-away project-rename project-reorder project-keep
        top-nested top-hitters
      ].freeze

      # Let / query statements
      STATEMENT_KEYWORDS = %w[
        let set with
      ].freeze

      # Scalar functions and aggregations
      FUNCTIONS = %w[
        ago now todatetime totimespan datetime_add datetime_diff datetime_part
        startofday endofday startofweek endofweek startofmonth endofmonth
        startofyear endofyear weekofyear dayofweek dayofmonth dayofyear
        hourofday getyear getmonth format_datetime format_timespan
        bin bin_at floor ceiling round abs sqrt log log2 log10 exp exp2 exp10
        pow sign isnan isinf isfinite
        tostring toint tolong todouble toreal tobool toboolnull
        todynamic toobject toguid
        strlen substring indexof indexofregex split strcat strcat_delim
        replace replace_regex trim trim_start trim_end tolower toupper
        reverse countof extract extract_all parse_url parse_path parse_ipv4
        has_any has_all in_range between
        isempty isnotempty isnull isnotnull
        iff iif case coalesce
        array_length array_concat array_slice array_split array_iif
        array_index_of array_sort_asc array_sort_desc array_rotate_left array_rotate_right
        bag_keys bag_has_key bag_merge bag_remove_keys bag_set_key bag_pack bag_unpack bag_zip
        pack pack_all pack_array unpack
        zip
        geo_point_to_s2cell s2cell_to_central_point geo_distance_2points
        geo_point_in_polygon geo_point_in_circle
        hash hash_sha256 hash_md5 hash_xxhash64
        base64_encode_tostring base64_decode_tostring
        gzip_compress_to_base64_string gzip_decompress_from_base64_string
        url_encode url_decode
        make_datetime make_timespan
        materialize
        count sum avg min max stdev variance
        dcount dcountif
        countif sumif avgif maxif minif
        any anyif
        percentile percentiles percentilew percentilesw
        make_list make_set make_list_with_nulls make_list_if make_set_if
        buildschema
        series_stats series_outliers series_periods_detect series_periods_validate
        series_fit_line series_fit_2lines
        arg_min arg_max
        take_any
        row_number row_rank row_cumsum row_window_session
        prev next
        estimate_data_size
      ].freeze

      # Data types
      TYPES = %w[
        bool boolean int long real double string datetime timespan dynamic
        decimal guid uniqueid
      ].freeze

      # Boolean / null constants
      CONSTANTS = %w[
        true false null
      ].freeze

      # Join kinds
      JOIN_KINDS = %w[
        inner innerunique leftouter rightouter fullouter leftanti leftantisemi
        rightanti rightantisemi leftsemi rightsemi
      ].freeze

      # Predicates / operators (word-form)
      PREDICATES = %w[
        and or not has contains startswith endswith matches hasprefix hassuffix
        in notin between !in !between !has !contains !startswith !endswith
        has_cs contains_cs startswith_cs endswith_cs hasprefix_cs hassuffix_cs
        of as kind on asc desc nulls
      ].freeze

      ALL_KEYWORDS = (TABULAR_OPERATORS + STATEMENT_KEYWORDS + JOIN_KINDS + PREDICATES + CONSTANTS).freeze
      ALL_FUNCTIONS = (FUNCTIONS).freeze
      ALL_TYPES     = (TYPES).freeze

      state :root do
        rule %r/\s+/, Text::Whitespace

        # Single-line comment
        rule %r(//.*?$), Comment::Single

        # Multi-line comment
        rule %r(/\*.*?\*/)m, Comment::Multiline

        # Control commands (.show, .execute, .set-or-append, etc.)
        rule %r/\.[a-zA-Z][\w-]*/, Name::Decorator

        # Pipe operator
        rule %r/\|/, Punctuation

        # Strings: double-quoted
        rule %r/"/, Str::Double, :double_string

        # Strings: single-quoted
        rule %r/'/, Str::Single, :single_string

        # Verbatim strings: h@"..." or @"..."
        rule %r/[hH]?@"/, Str::Double, :verbatim_dstring
        rule %r/[hH]?@'/, Str::Single, :verbatim_sstring

        # Timespan literals: 1d, 2h, 30m, 1s, 1ms, 1microsecond, 1tick
        rule %r/\b\d+(?:\.\d+)?(?:d|h|m|s|ms|microseconds?|ticks?)\b/, Num

        # Hex numbers
        rule %r/\b0x[0-9a-fA-F]+\b/, Num::Hex

        # Float
        rule %r/\b\d+\.\d+(?:[eE][+-]?\d+)?[lLdDfF]?\b/, Num::Float

        # Integer
        rule %r/\b\d+(?:[eE][+-]?\d+)?[lL]?\b/, Num::Integer

        # Identifiers / keywords
        rule %r/\b[a-zA-Z_][\w]*\b/ do |m|
          word = m[0].downcase
          if ALL_KEYWORDS.include?(word)
            token Keyword
          elsif ALL_TYPES.include?(word)
            token Keyword::Type
          elsif ALL_FUNCTIONS.include?(word)
            token Name::Builtin
          else
            token Name
          end
        end

        # Quoted identifiers: ['column name'] or ["column name"]
        rule %r/\['[^']*'\]/, Name::Variable
        rule %r/\["[^"]*"\]/, Name::Variable

        # Operators
        rule %r/[=!<>]=?|[+\-*\/]|=~|!~|\b(?:and|or|not)\b/, Operator

        # Punctuation
        rule %r/[{}()\[\],;.]/, Punctuation

        rule %r/./, Text
      end

      state :double_string do
        rule %r/\\[\\nrt"']/, Str::Escape
        rule %r/"/, Str::Double, :pop!
        rule %r/[^"\\]+/, Str::Double
      end

      state :single_string do
        rule %r/\\[\\nrt"']/, Str::Escape
        rule %r/'/, Str::Single, :pop!
        rule %r/[^'\\]+/, Str::Single
      end

      state :verbatim_dstring do
        rule %r/""/, Str::Escape
        rule %r/"/, Str::Double, :pop!
        rule %r/[^"]+/, Str::Double
      end

      state :verbatim_sstring do
        rule %r/''/, Str::Escape
        rule %r/'/, Str::Single, :pop!
        rule %r/[^']+/, Str::Single
      end
    end
  end
end
