def compute_multi_interval_variation(padron_clean,
                                     year_col="Year",
                                     pop_col="Pop",
                                     index_cols=("Mun_Code", "Mun"),
                                     start_year=1996, 
                                     end_year=2024):
    """
    Compute percent population variation for multiple interval lengths (k) between years.

    Parameters
    ----------
    padron_clean : pandas.DataFrame
        Clean long-format dataframe containing at least the columns in index_cols, year_col and pop_col.
        Example rows: Year, Mun_Code_Mun, Year, Total.
    year_col : str, default "Periodo"
        Column name that stores the year (int).
    pop_col : str, default "Pop"
        Column name that stores population counts (numeric).
    index_cols : tuple, default ("Mun_Code", "Mun")
        Columns to use as the unique identifier for each municipality (will become the dataframe index).
    start_year : int, default 1996
        First year in the series.
    end_year : int, default 2024
        Last year in the series.
    
    Returns
    -------
    df_all : pandas.DataFrame
        Wide dataframe indexed by index_cols containing one column per (start,end,k) with names like:
        "pop_1996_2003 (k=7)" with percent variation values.
    dict_per_k : dict
        Dictionary mapping each integer k (1..end_year-start_year) to a DataFrame with variation columns
        only for that k (useful for saving one CSV per k).
        """
    
    import pandas as pd
    import numpy as np

    # 1) pivot to wide format: rows = municipality, cols = years
    pivot = (
        padron_clean
        .pivot_table(index=list(index_cols), columns=year_col, values=pop_col, aggfunc="sum")
        .sort_index(axis=1)  # ensure years sorted left->right
    )

    # 2) prepare outputs
    df_all = pivot.copy()  # we'll append variation cols to a copy (optional keep original years)
    # If you don't want to keep year columns in df_all, you can start df_all = pivot[[]].copy()
    dict_per_k = {}

    k_max = end_year - start_year

    for k in range(1, k_max + 1):
        cols_for_k = []
        df_k = pd.DataFrame(index=pivot.index)  # will hold variation columns for this k
        for y in range(start_year, end_year - k + 1):
            y_end = y + k
            # check both year columns exist
            if y in pivot.columns and y_end in pivot.columns:
                col_start = pivot[y]
                col_end = pivot[y_end]

                # avoid division by zero: where start is 0 or NaN -> result NaN
                valid = col_start.replace({0: np.nan}).notna()

                variation = (col_end - col_start) / col_start * 100
                variation = variation.where(valid, other=np.nan)

                col_name = f"pop_{y}_{y_end} (k={k})"
                df_k[col_name] = variation
                cols_for_k.append(col_name)
            else:
                # missing year column(s) => skip this pair
                continue

        # store df_k (may be empty if no valid pairs for this k)
        dict_per_k[k] = df_k
        # append these columns to df_all
        if not df_k.empty:
            df_all = pd.concat([df_all, df_k], axis=1)

    # optionally drop the original year columns from df_all if you want only variation columns:
    # year_cols = [c for c in df_all.columns if isinstance(c, int)]  # integer-year columns
    # df_all = df_all.drop(columns=year_cols)

    return df_all, dict_per_k